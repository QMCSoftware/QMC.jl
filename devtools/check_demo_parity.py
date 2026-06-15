#!/usr/bin/env python3
"""
check_demo_parity.py — audit QMC.jl demo notebooks against their QMCPy sources.

Two independent checks, selectable with --mode:

  conformance   Static checks on every QMC.jl/demos notebook (no runtime needed):
                  - parses as valid JSON
                  - has an `Original QMCPy demo:` front-matter line (translated demos only)
                  - has an Open-In-Colab badge (translated demos only)
                  - no mid-sentence hard line breaks in markdown prose
                  - no stale outputs (cell has outputs but execution_count is null)
                These map to requirements 5, 6, 7, 18, 19 of
                sc_notes/demo_translation_prompt.md and are authoritative.

  parity        Best-effort numeric comparison of each translated Julia notebook
                against its QMCPy source, using each notebook's SAVED outputs.
                Numbers are aligned by the text label that precedes them
                ("solution: 1.234"); shared labels are compared within tolerance.
                This is a TRIAGE signal for requirements 10-13, not a proof:
                it tells you which notebooks deserve a closer manual look.
                Re-run after `make notebook-update` so the Julia outputs are fresh.

  both          Run conformance then parity (default).

Usage:
  # Run from QMCSoftware folder that contains both QMC.jl and QMCPy
  python3 QMC.jl/devtools/check_demo_parity.py   
  python3 QMC.jl/devtools/check_demo_parity.py --mode conformance
  python3 QMC.jl/devtools/check_demo_parity.py --mode parity --rtol 1e-2 --atol 1e-6
  python3 QMC.jl/devtools/check_demo_parity.py --jl-root QMC.jl/demos --py-root QMCPy/demos
  python3 QMC.jl/devtools/check_demo_parity.py --json report.json

Exit code is non-zero if any conformance check fails (parity mismatches do not
fail the build, since they are heuristic).
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import defaultdict

# --- notebook basename renames: QMC.jl side -> QMCPy side (without .ipynb) -----
# Only the cases where the two repos do not share an identical relative path.
RENAME_JL_TO_PY = {
    "qei_demo": "qei-demo-for-blog",
    "qmc.jl_intro": "qmcpy_intro",
    "asian_option_mlqmc": "asian-option-mlqmc",
    "elliptic_pde": "elliptic-pde",
    "linear_scrambled_halton": "linear-scrambled-halton",
}
# Explicit full-path overrides (Julia rel path -> QMCPy rel path) for the few
# notebooks that moved directory between the two repos.
PATH_OVERRIDE = {
    "gbm_demo.ipynb": "GBM/gbm_demo.ipynb",
}
# Julia-only demos: no QMCPy original, so skip the translation-only checks.
JULIA_ONLY = {
    "financial_option_ml.ipynb",
    "kronecker.ipynb",
    "sensitivity_indices.ipynb",
    "lattice.ipynb",
}

NUM_RE = re.compile(
    r"[-+]?(?:\d{1,3}(?:[, ]\d{3})+|\d+)(?:\.\d+)?(?:[eE][-+]?\d+)?"
)
# A label is a short run of word-ish characters right before a : or = and a number.
LABEL_NUM_RE = re.compile(
    r"([A-Za-z][\w '().%/-]{0,40}?)\s*[:=]\s*\(?\s*"
    r"([-+]?(?:\d+)?(?:\.\d+)?(?:[eE][-+]?\d+)?)"
)


# ----------------------------------------------------------------------------- helpers
def load(path):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def cell_src(cell):
    s = cell.get("source", [])
    return "".join(s) if isinstance(s, list) else (s or "")


def markdown_cells(nb):
    return [c for c in nb.get("cells", []) if c.get("cell_type") == "markdown"]


def code_cells(nb):
    return [c for c in nb.get("cells", []) if c.get("cell_type") == "code"]


def output_text(cell):
    """Concatenate all human-visible text from a code cell's saved outputs."""
    chunks = []
    for o in cell.get("outputs", []):
        ot = o.get("output_type")
        if ot == "stream":
            t = o.get("text", "")
            chunks.append("".join(t) if isinstance(t, list) else t)
        elif ot in ("execute_result", "display_data"):
            data = o.get("data", {})
            t = data.get("text/plain", "")
            chunks.append("".join(t) if isinstance(t, list) else t)
        elif ot == "error":
            chunks.append("\n".join(o.get("traceback", [])))
    return "\n".join(chunks)


def all_output_text(nb):
    return "\n".join(output_text(c) for c in code_cells(nb))


def to_float(tok):
    try:
        return float(tok.replace(",", "").replace(" ", ""))
    except ValueError:
        return None


def _png_dims(raw):
    """(width, height) from a PNG IHDR chunk, or None."""
    if len(raw) >= 24 and raw[:8] == b"\x89PNG\r\n\x1a\n":
        return int.from_bytes(raw[16:20], "big"), int.from_bytes(raw[20:24], "big")
    return None


def embedded_figures(nb, min_bytes=2000):
    """List of dicts for each raster figure in saved outputs.

    Tiny SVG placeholders and sub-`min_bytes` thumbnails are skipped so the
    count reflects real plots, not backend artifacts.
    """
    import base64

    figs = []
    for ci, c in enumerate(nb.get("cells", [])):
        if c.get("cell_type") != "code":
            continue
        for o in c.get("outputs", []):
            data = o.get("data", {}) or {}
            for mt, v in data.items():
                if not mt.startswith("image/") or "svg" in mt:
                    continue
                b = "".join(v) if isinstance(v, list) else v
                try:
                    raw = base64.b64decode(b)
                except Exception:  # noqa: BLE001
                    continue
                if len(raw) < min_bytes:
                    continue
                dims = _png_dims(raw)
                figs.append({
                    "cell": ci, "mime": mt, "bytes": len(raw),
                    "w": dims[0] if dims else None,
                    "h": dims[1] if dims else None,
                    "aspect": round(dims[0] / dims[1], 2) if dims and dims[1] else None,
                })
    return figs


def _julia_plot_calls(nb):
    markers = ("plot(", "plot!(", "scatter(", "scatter!(", "heatmap(",
               "histogram(", "surface(", "contour(", "bar(", "Plots.")
    n = 0
    for c in nb.get("cells", []):
        if c.get("cell_type") != "code":
            continue
        s = "".join(c.get("source", []))
        if any(m in s for m in markers):
            n += 1
    return n


def _executed(nb):
    return any(
        c.get("cell_type") == "code" and c.get("outputs")
        for c in nb.get("cells", [])
    )


def figures(jl_root, py_root, pairs):
    rows = []
    for jl_rel, py_rel in pairs:
        rec = {"notebook": jl_rel, "py": py_rel}
        try:
            jl_nb = load(os.path.join(jl_root, jl_rel))
            py_nb = load(os.path.join(py_root, py_rel))
        except Exception as e:  # noqa: BLE001
            rec.update(status="load-error", detail=str(e))
            rows.append(rec)
            continue
        jl_f = embedded_figures(jl_nb)
        py_f = embedded_figures(py_nb)
        nj, npy = len(jl_f), len(py_f)
        plot_calls = _julia_plot_calls(jl_nb)
        executed = _executed(jl_nb)
        # classify
        if npy == 0:
            cls = "no-py-figs"
        elif nj == npy:
            cls = "match-count"
        elif nj == 0 and plot_calls == 0:
            cls = "TEXT-ONLY PORT"
        elif nj == 0 and plot_calls > 0 and executed:
            cls = "figures-not-embedded"   # plots in code but no images saved
        elif nj == 0:
            cls = "no-jl-figs"
        else:
            cls = "FEWER FIGURES"
        rec.update(
            status="ok", jl_figs=nj, py_figs=npy, jl_plot_calls=plot_calls,
            jl_executed=executed, classification=cls,
            jl_aspects=[f["aspect"] for f in jl_f],
            py_aspects=[f["aspect"] for f in py_f],
        )
        rows.append(rec)
    return rows


def print_figures(rows):
    print("\n" + "=" * 78)
    print("FIGURES (heuristic) — req 15: figure coverage vs QMCPy")
    print("=" * 78)
    print(f"{'notebook':40} {'jl':>3} {'py':>3} {'plt':>3}  classification")
    order = {"TEXT-ONLY PORT": 0, "FEWER FIGURES": 1, "figures-not-embedded": 2,
             "no-jl-figs": 3, "match-count": 4, "no-py-figs": 5}
    for r in sorted(rows, key=lambda r: order.get(r.get("classification"), 9)):
        if r["status"] != "ok":
            print(f"{r['notebook']:40} {'-':>3} {'-':>3} {'-':>3}  {r['status']}")
            continue
        print(f"{r['notebook']:40} {r['jl_figs']:>3} {r['py_figs']:>3} "
              f"{r['jl_plot_calls']:>3}  {r['classification']}")
    print("\nLegend:")
    print("  TEXT-ONLY PORT       Julia has no plots and no plotting calls; QMCPy")
    print("                       has figures. Real req-15 gap (visual -> text).")
    print("  FEWER FIGURES        Julia plots fewer figures than QMCPy.")
    print("  figures-not-embedded Julia code plots but no image was saved; rerun")
    print("                       `make notebook-update`, then re-check (req 19).")
    print("  match-count          Same number of figures (content still needs eyes).")
    print("  no-py-figs           QMCPy source has no figures to match.")
    print("\nNote: counts and the text-only flag are reliable; equal counts do NOT")
    print("prove the plots match in data, layout, or labels — that still needs a look.")


# ----------------------------------------------------------------------------- mapping
def list_notebooks(root):
    out = []
    for dp, _, fs in os.walk(root):
        if ".ipynb_checkpoints" in dp:
            continue
        for f in fs:
            if f.endswith(".ipynb") and not f.endswith("-checkpoint.ipynb"):
                full = os.path.join(dp, f)
                out.append(os.path.relpath(full, root))
    return sorted(out)


def jl_to_py_relpath(jl_rel):
    if jl_rel in PATH_OVERRIDE:
        return PATH_OVERRIDE[jl_rel]
    d = os.path.dirname(jl_rel)
    base = os.path.basename(jl_rel)[:-6]
    py_base = RENAME_JL_TO_PY.get(base, base)
    return os.path.join(d, py_base + ".ipynb") if d else py_base + ".ipynb"


def build_pairs(jl_root, py_root):
    """Return (pairs, jl_only, py_only). pairs: list of (jl_rel, py_rel)."""
    jl = list_notebooks(jl_root)
    py = set(list_notebooks(py_root))
    pairs, jl_only = [], []
    matched_py = set()
    for j in jl:
        if j in JULIA_ONLY:
            jl_only.append(j)
            continue
        cand = jl_to_py_relpath(j)
        # also try the dash/underscore swap if exact miss
        if cand not in py:
            alt = cand.replace("_", "-")
            cand = alt if alt in py else cand
        if cand in py:
            pairs.append((j, cand))
            matched_py.add(cand)
        else:
            jl_only.append(j)
    py_only = sorted(py - matched_py)
    return pairs, jl_only, py_only


# ----------------------------------------------------------------------------- conformance
def midsentence_breaks(nb):
    hits = 0
    for c in markdown_cells(nb):
        lines = cell_src(c).split("\n")
        fence = math = False
        for i in range(len(lines) - 1):
            ls, ns = lines[i].strip(), lines[i + 1].strip()
            if ls.startswith("```"):
                fence = not fence
                continue
            if fence:
                continue
            if ls == "$$":
                math = not math
                continue
            if math:
                continue
            skip = ("#", "-", "*", "+", "|", ">")
            if not ls or ls.startswith(skip) or re.match(r"^\d+\.", ls):
                continue
            if (not ns or ns.startswith(skip + ("```", "$$"))
                    or re.match(r"^\d+\.", ns)):
                continue
            if re.search(r"[a-z,]$", ls) and re.match(r"^[a-z]", ns):
                hits += 1
    return hits


def stale_outputs(nb):
    return sum(
        1 for c in code_cells(nb)
        if c.get("outputs") and c.get("execution_count") is None
    )


def conformance(jl_root, pairs, jl_only):
    translated = {j for j, _ in pairs}
    rows = []
    failures = 0
    for jl_rel in sorted(translated | set(jl_only)):
        path = os.path.join(jl_root, jl_rel)
        rec = {"notebook": jl_rel, "translated": jl_rel in translated}
        try:
            nb = load(path)
            rec["json_ok"] = True
        except Exception as e:  # noqa: BLE001
            rec.update(json_ok=False, error=str(e))
            rows.append(rec)
            failures += 1
            continue
        md = "\n".join(cell_src(c) for c in markdown_cells(nb))
        rec["colab"] = "colab.research.google.com" in md
        rec["orig_ref"] = bool(re.search(r"Original QMCPy demo\s*:", md))
        rec["midbreaks"] = midsentence_breaks(nb)
        rec["stale"] = stale_outputs(nb)
        # which requirements fail
        fails = []
        if not rec["json_ok"]:
            fails.append("JSON(18)")
        if rec["midbreaks"]:
            fails.append(f"midbreaks={rec['midbreaks']}(5)")
        if rec["stale"]:
            fails.append(f"stale={rec['stale']}(19)")
        if rec["translated"]:
            if not rec["orig_ref"]:
                fails.append("no-orig-ref(6)")
            if not rec["colab"]:
                fails.append("no-colab(7)")
        rec["fails"] = fails
        if fails:
            failures += 1
        rows.append(rec)
    return rows, failures


# ----------------------------------------------------------------------------- parity
def labeled_numbers(text):
    """label(lowercased) -> list of floats, in encounter order."""
    d = defaultdict(list)
    for m in LABEL_NUM_RE.finditer(text):
        label = re.sub(r"\s+", " ", m.group(1).strip().lower())
        val = to_float(m.group(2))
        if val is not None and label:
            d[label].append(val)
    return d


def flat_numbers(text):
    out = []
    for m in NUM_RE.finditer(text):
        v = to_float(m.group(0))
        if v is not None:
            out.append(v)
    return out


def close(a, b, rtol, atol):
    return abs(a - b) <= atol + rtol * max(abs(a), abs(b))


def parity(jl_root, py_root, pairs, rtol, atol):
    rows = []
    for jl_rel, py_rel in pairs:
        rec = {"notebook": jl_rel, "py": py_rel}
        try:
            jl_nb = load(os.path.join(jl_root, jl_rel))
            py_nb = load(os.path.join(py_root, py_rel))
        except Exception as e:  # noqa: BLE001
            rec.update(status="load-error", detail=str(e))
            rows.append(rec)
            continue
        jl_txt, py_txt = all_output_text(jl_nb), all_output_text(py_nb)
        if not jl_txt.strip():
            rec.update(status="no-jl-output",
                       detail="Julia notebook has no saved outputs; "
                              "run `make notebook-update` first.")
            rows.append(rec)
            continue
        if not py_txt.strip():
            rec.update(status="no-py-output",
                       detail="QMCPy source has no saved outputs to compare.")
            rows.append(rec)
            continue
        jl_lab, py_lab = labeled_numbers(jl_txt), labeled_numbers(py_txt)
        shared = sorted(set(jl_lab) & set(py_lab))
        compared = matched = 0
        mism = []
        for lab in shared:
            jv, pv = jl_lab[lab], py_lab[lab]
            for a, b in zip(jv, pv):  # align by position within a shared label
                compared += 1
                if close(a, b, rtol, atol):
                    matched += 1
                else:
                    mism.append((lab, a, b))
        rec.update(
            status="ok",
            shared_labels=len(shared),
            compared=compared,
            matched=matched,
            mismatches=mism[:25],
            n_mismatch=len(mism),
        )
        # secondary heuristic: overall count of numbers in outputs
        rec["jl_numbers"] = len(flat_numbers(jl_txt))
        rec["py_numbers"] = len(flat_numbers(py_txt))
        rows.append(rec)
    return rows


# ----------------------------------------------------------------------------- reporting
def print_conformance(rows, failures):
    print("=" * 78)
    print("CONFORMANCE (authoritative) — reqs 5,6,7,18,19")
    print("=" * 78)
    hdr = f"{'notebook':52} {'JSON':4} {'COL':3} {'ORG':3} {'BRK':3} {'STALE':5}"
    print(hdr)
    for r in rows:
        if not r.get("json_ok"):
            print(f"{r['notebook']:52} FAIL  (JSON: {r.get('error','')[:30]})")
            continue
        tag = "" if not r["fails"] else "   <-- " + ", ".join(r["fails"])
        col = "Y" if r["colab"] else ("-" if r["translated"] else ".")
        org = "Y" if r["orig_ref"] else ("-" if r["translated"] else ".")
        print(f"{r['notebook']:52} {'ok':4} {col:3} {org:3} "
              f"{r['midbreaks']:<3} {r['stale']:<5}{tag}")
    print(f"\nConformance failures: {failures}")


def print_parity(rows, rtol, atol):
    print("\n" + "=" * 78)
    print(f"PARITY (heuristic triage) — reqs 10-13   rtol={rtol} atol={atol}")
    print("=" * 78)
    print(f"{'notebook':40} {'shared':6} {'cmp':4} {'ok':4} {'bad':4} status")
    for r in rows:
        if r["status"] != "ok":
            print(f"{r['notebook']:40} {'-':6} {'-':4} {'-':4} {'-':4} "
                  f"{r['status']}: {r.get('detail','')[:30]}")
            continue
        print(f"{r['notebook']:40} {r['shared_labels']:<6} {r['compared']:<4} "
              f"{r['matched']:<4} {r['n_mismatch']:<4} ok")
    print("\nFlagged mismatches (shared label, julia vs qmcpy):")
    any_flag = False
    for r in rows:
        if r["status"] == "ok" and r["mismatches"]:
            any_flag = True
            print(f"  {r['notebook']}:")
            for lab, a, b in r["mismatches"]:
                print(f"     {lab!r:30} jl={a:<14g} py={b:<14g}")
    if not any_flag:
        print("  (none above tolerance among shared labels)")
    print("\nNote: parity is a triage signal, not a proof. Label-based alignment")
    print("misses unlabeled values and cannot align reworded labels; a clean line")
    print("here means 'nothing obviously diverged', not 'verified equivalent'.")


# ----------------------------------------------------------------------------- main
def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--mode",
                    choices=["conformance", "parity", "figures", "both"],
                    default="both")
    ap.add_argument("--jl-root", default="QMC.jl/demos")
    ap.add_argument("--py-root", default="QMCPy/demos")
    ap.add_argument("--rtol", type=float, default=1e-2)
    ap.add_argument("--atol", type=float, default=1e-8)
    ap.add_argument("--json", metavar="PATH", help="also write a JSON report")
    args = ap.parse_args()

    if not os.path.isdir(args.jl_root) or not os.path.isdir(args.py_root):
        sys.exit(f"error: run from repo root containing {args.jl_root} and "
                 f"{args.py_root} (or pass --jl-root/--py-root).")

    pairs, jl_only, py_only = build_pairs(args.jl_root, args.py_root)
    report = {"pairs": len(pairs), "jl_only": jl_only, "py_only": py_only}
    exit_code = 0

    if args.mode in ("conformance", "both"):
        rows, failures = conformance(args.jl_root, pairs, jl_only)
        print_conformance(rows, failures)
        report["conformance"] = rows
        report["conformance_failures"] = failures
        if failures:
            exit_code = 1

    if args.mode in ("parity", "both"):
        prows = parity(args.jl_root, args.py_root, pairs, args.rtol, args.atol)
        print_parity(prows, args.rtol, args.atol)
        report["parity"] = prows

    if args.mode in ("figures", "both"):
        frows = figures(args.jl_root, args.py_root, pairs)
        print_figures(frows)
        report["figures"] = frows

    print("\n" + "=" * 78)
    print("COVERAGE")
    print("=" * 78)
    print(f"translated pairs : {len(pairs)}")
    print(f"julia-only demos : {len(jl_only)} -> {', '.join(jl_only) or '(none)'}")
    print(f"untranslated QMCPy ({len(py_only)}):")
    for p in py_only:
        print(f"   {p}")

    if args.json:
        with open(args.json, "w", encoding="utf-8") as f:
            json.dump(report, f, indent=2)
        print(f"\nwrote {args.json}")

    sys.exit(exit_code)


if __name__ == "__main__":
    main()
