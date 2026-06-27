#!/usr/bin/env python3
"""Generate the checked-in QMCPy 2.3 release-parity fixture for QMC.jl.

This script requires the pinned QMCPy benchmark environment:

    pip install -r benchmark/requirements.txt

It writes a Julia source file that can be included directly by the
release-parity test runner, avoiding any extra parser dependency in the main Julia test environment.
"""

from __future__ import annotations

import math
from datetime import datetime, timezone
from pathlib import Path
from typing import Any
import warnings

import numpy as np
import qmcpy as qp


ROOT = Path(__file__).resolve().parents[1]
OUTFILE = ROOT / "test" / "qmcpy23_release_parity_fixture.jl"
SEED = 42
ORACLE_ROWS = 4


def dense_covariance(dim: int) -> np.ndarray:
    cov = np.full((dim, dim), 0.5)
    np.fill_diagonal(cov, 1.0)
    return cov


def oracle_uniform_matrix(rows: int, dim: int, offset: int = 0) -> np.ndarray:
    ii = np.arange(1, rows + 1, dtype=np.int64)[:, None]
    jj = np.arange(1, dim + 1, dtype=np.int64)[None, :]
    numer = (37 * ii + 17 * jj + 13 * offset) % 997
    return (numer.astype(np.float64) + 0.5) / 997.0


def genz_gaussian_peak(x: np.ndarray) -> np.ndarray:
    shifted = x - 0.5
    return np.exp(-np.sum(shifted * shifted, axis=1))


def genz_continuous(x: np.ndarray) -> np.ndarray:
    return np.exp(-np.sum(np.abs(x - 0.5), axis=1))


def flat_row_major(values: Any) -> list[float]:
    arr = np.asarray(values, dtype=float)
    if arr.ndim == 0:
        return [float(arr)]
    if arr.ndim == 1:
        return [float(x) for x in arr.tolist()]
    return [float(x) for x in arr.reshape(-1).tolist()]


def exact_entry(values: Any, *, atol: float, rtol: float) -> dict[str, Any]:
    arr = np.asarray(values, dtype=float)
    return {
        "shape": [int(x) for x in arr.shape],
        "values": flat_row_major(arr),
        "atol": float(atol),
        "rtol": float(rtol),
    }


def scalar(x: Any) -> float:
    return float(np.asarray(x).reshape(-1)[0])


def criterion_entry(
    solution: Any,
    data: Any,
    *,
    abs_tol: float,
    rel_tol: float = 0.0,
    extra: dict[str, Any] | None = None,
) -> dict[str, Any]:
    out = {
        "solution": scalar(solution),
        "abs_tol": float(abs_tol),
        "rel_tol": float(rel_tol),
    }
    for attr in ("n", "n_total", "n_rep", "levels", "replications"):
        if hasattr(data, attr):
            out[attr] = int(getattr(data, attr))
    if hasattr(data, "n_level"):
        out["n_level"] = [int(x) for x in np.asarray(data.n_level).tolist()]
    if extra:
        out.update(extra)
    return out


def resume_entry(loose: Any, resumed: Any, *, loose_abs_tol: float, resumed_abs_tol: float) -> dict[str, Any]:
    _, loose_data = loose
    _, resumed_data = resumed
    return {
        "loose": criterion_entry(loose[0], loose_data, abs_tol=loose_abs_tol),
        "resumed": {
            **criterion_entry(resumed[0], resumed_data, abs_tol=resumed_abs_tol),
            "resumed": bool(getattr(resumed_data, "resumed", False)),
            "n_resume_from": int(getattr(resumed_data, "n_resume_from", 0)),
        },
    }


def finance_option_sampler_qmc() -> qp.FinancialOption:
    return qp.FinancialOption(
        qp.Lattice(16, seed=7, replications=8),
        option="ASIAN",
        volatility=0.2,
        start_price=100,
        strike_price=100,
        interest_rate=0.05,
        t_final=1,
        level=None,
        d_coarsest=4,
    )


def collect_fixture() -> dict[str, Any]:
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")

        lattice_det = qp.Lattice(2, randomize=False, order="RADICAL INVERSE")
        dnb2_det = qp.DigitalNetB2(2, randomize=False, order="RADICAL INVERSE")
        halton_det = qp.Halton(2, randomize=False)

        lattice_child = lattice_det.spawn(s=1, dimensions=[4])[0]
        dnb2_child = dnb2_det.spawn(s=1, dimensions=[4])[0]
        halton_child = halton_det.spawn(s=1, dimensions=[4])[0]

        dd3 = qp.IIDStdUniform(3, seed=SEED)
        dd10 = qp.IIDStdUniform(10, seed=SEED)
        dd50 = qp.IIDStdUniform(50, seed=SEED)
        dd1 = qp.IIDStdUniform(1, seed=SEED)

        keister = qp.Keister(dd3)
        genz_osc = qp.Genz(dd3, kind_func="OSCILLATORY")

        cubmcclt = qp.CubMCCLT(qp.Keister(qp.IIDStdUniform(3, seed=SEED)), abs_tol=1.0, rel_tol=0.01).integrate()
        cubqmcnetg = qp.CubQMCNetG(
            qp.Keister(qp.DigitalNetB2(3, seed=SEED)),
            abs_tol=0.05,
            n_init=2**8,
            n_limit=2**12,
        ).integrate()
        cubqmc_rep = qp.CubQMCRepStudentT(
            qp.Keister(qp.DigitalNetB2(3, seed=SEED, replications=8)),
            abs_tol=0.05,
            n_init=2**8,
            n_limit=2**12,
        ).integrate()

        mlqmc = qp.CubMLQMC(
            finance_option_sampler_qmc(),
            abs_tol=1.0,
            n_init=32,
            levels_min=2,
            levels_max=3,
        ).integrate()
        mlqmc_cont = qp.CubMLQMCCont(
            finance_option_sampler_qmc(),
            abs_tol=1.0,
            n_init=32,
            levels_min=2,
            levels_max=3,
            n_tols=3,
        ).integrate()

        loose_resume = qp.CubQMCRepStudentT(
            qp.Keister(qp.DigitalNetB2(3, seed=SEED, replications=8)),
            abs_tol=0.5,
            n_init=2**8,
            n_limit=2**9,
        ).integrate()
        resumed_resume = qp.CubQMCRepStudentT(
            qp.Keister(qp.DigitalNetB2(3, seed=SEED, replications=8)),
            abs_tol=0.05,
            n_init=2**8,
            n_limit=2**12,
        ).integrate(resume=loose_resume[1])

        return {
            "metadata": {
                "qmcpy_version": str(getattr(qp, "__version__", "?")),
                "generated_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
                "generator_policy": "Exact deterministic low-discrepancy samples/spawns only; randomized generator bit-parity is intentionally out of scope for this release gate.",
                "criterion_policy": "Stopping-criterion cases compare solutions within 2*max(abs_tol, rel_tol*|reference|) and enforce exact sample-accounting contracts where the seeded QMCPy 2.3 data is stable.",
                "multilevel_policy": "Multilevel/continuation cases compare solutions within 2*max(abs_tol, rel_tol*|reference|), require exact levels/replications, and require QMC.jl to do no less per-level work than the pinned QMCPy 2.3 reference.",
                "resume_policy": "Resume cases enforce QMCPy-derived monotonic accounting and solution-within-tolerance semantics; randomized resumed sample counts need not match exactly.",
            },
            "gen_samples": {
                "Lattice base deterministic": exact_entry(lattice_det.gen_samples(4), atol=1e-12, rtol=0.0),
                "DigitalNetB2 base deterministic": exact_entry(dnb2_det.gen_samples(4), atol=1e-12, rtol=0.0),
                "Halton base deterministic": exact_entry(halton_det.gen_samples(4), atol=1e-12, rtol=0.0),
            },
            "spawn": {
                "Lattice spawn deterministic": exact_entry(lattice_child.gen_samples(4), atol=1e-12, rtol=0.0),
                "DigitalNetB2 spawn deterministic": exact_entry(dnb2_child.gen_samples(4), atol=1e-12, rtol=0.0),
                "Halton spawn deterministic": exact_entry(halton_child.gen_samples(4), atol=1e-12, rtol=0.0),
            },
            "transform": {
                "Gaussian d=3 rows=4": exact_entry(
                    qp.Gaussian(dd3, decomp_type="Cholesky")._transform(
                        oracle_uniform_matrix(ORACLE_ROWS, 3, offset=1)
                    ),
                    atol=1e-10,
                    rtol=1e-10,
                ),
                "Gaussian(dense) d=50 rows=3": exact_entry(
                    qp.Gaussian(dd50, covariance=dense_covariance(50), decomp_type="Cholesky")._transform(
                        oracle_uniform_matrix(3, 50, offset=3)
                    ),
                    atol=5e-10,
                    rtol=5e-10,
                ),
                "StudentT d=1 rows=4": exact_entry(
                    qp.StudentT(dd1, loc=np.zeros(1), shape=np.eye(1), df=2.0)._transform(
                        oracle_uniform_matrix(ORACLE_ROWS, 1, offset=4)
                    ),
                    atol=1e-7,
                    rtol=1e-7,
                ),
                "JohnsonsSU d=10 rows=4": exact_entry(
                    qp.JohnsonsSU(dd10)._transform(
                        oracle_uniform_matrix(ORACLE_ROWS, 10, offset=5)
                    ),
                    atol=1e-10,
                    rtol=1e-10,
                ),
            },
            "evaluate": {
                "Keister rows=4": exact_entry(
                    keister.g(keister.true_measure._transform(oracle_uniform_matrix(ORACLE_ROWS, 3, offset=11))),
                    atol=1e-10,
                    rtol=1e-10,
                ),
                "Genz(oscillatory) rows=4": exact_entry(
                    genz_osc.g(genz_osc.true_measure._transform(oracle_uniform_matrix(ORACLE_ROWS, 3, offset=12))),
                    atol=1e-10,
                    rtol=1e-10,
                ),
                "BoxIntegral d=10 rows=4": exact_entry(
                    qp.BoxIntegral(dd10, s=1).g(oracle_uniform_matrix(ORACLE_ROWS, 10, offset=13)),
                    atol=1e-10,
                    rtol=1e-10,
                ),
                "Linear0 d=10 rows=4": exact_entry(
                    qp.Linear0(dd10).g(oracle_uniform_matrix(ORACLE_ROWS, 10, offset=14)),
                    atol=1e-10,
                    rtol=1e-10,
                ),
                "Genz(gaussian_peak) d=10 rows=4": exact_entry(
                    genz_gaussian_peak(oracle_uniform_matrix(ORACLE_ROWS, 10, offset=15)),
                    atol=1e-10,
                    rtol=1e-10,
                ),
                "Genz(continuous) d=10 rows=4": exact_entry(
                    genz_continuous(oracle_uniform_matrix(ORACLE_ROWS, 10, offset=16)),
                    atol=1e-10,
                    rtol=1e-10,
                ),
            },
            "stopping_criteria": {
                "CubMCCLT Keister rel_tol": criterion_entry(cubmcclt[0], cubmcclt[1], abs_tol=1.0, rel_tol=0.01),
                "CubQMCNetG Keister": criterion_entry(cubqmcnetg[0], cubqmcnetg[1], abs_tol=0.05),
                "CubQMCRepStudentT Keister": criterion_entry(
                    cubqmc_rep[0],
                    cubqmc_rep[1],
                    abs_tol=0.05,
                    extra={"replications": 8},
                ),
            },
            "multilevel": {
                "CubMLQMC AsianOption": criterion_entry(
                    mlqmc[0],
                    mlqmc[1],
                    abs_tol=1.0,
                    extra={"replications": 8},
                ),
            },
            "continuation": {
                "CubMLQMCCont AsianOption": criterion_entry(
                    mlqmc_cont[0],
                    mlqmc_cont[1],
                    abs_tol=1.0,
                    extra={"replications": 8},
                ),
            },
            "resume": {
                "CubQMCRepStudentT Keister": resume_entry(
                    loose_resume,
                    resumed_resume,
                    loose_abs_tol=0.5,
                    resumed_abs_tol=0.05,
                ),
            },
        }


def julia_literal(obj: Any, indent: int = 0) -> str:
    pad = " " * indent
    next_pad = " " * (indent + 4)

    if isinstance(obj, dict):
        if not obj:
            return "Dict{String, Any}()"
        items = []
        for key, value in obj.items():
            items.append(f'{next_pad}"{key}" => {julia_literal(value, indent + 4)}')
        return "Dict{String, Any}(\n" + ",\n".join(items) + f"\n{pad})"
    if isinstance(obj, list):
        if not obj:
            return "Any[]"
        if all(not isinstance(item, (dict, list)) for item in obj):
            return "[" + ", ".join(julia_literal(item, indent) for item in obj) + "]"
        items = ",\n".join(f"{next_pad}{julia_literal(item, indent + 4)}" for item in obj)
        return "Any[\n" + items + f"\n{pad}]"
    if isinstance(obj, str):
        return '"' + obj.replace("\\", "\\\\").replace('"', '\\"') + '"'
    if isinstance(obj, bool):
        return "true" if obj else "false"
    if isinstance(obj, int):
        return str(obj)
    if isinstance(obj, float):
        if math.isnan(obj):
            return "NaN"
        if math.isinf(obj):
            return "Inf" if obj > 0 else "-Inf"
        return repr(obj)
    raise TypeError(f"unsupported literal type: {type(obj)!r}")


def main() -> None:
    fixture = collect_fixture()
    OUTFILE.parent.mkdir(parents=True, exist_ok=True)
    with OUTFILE.open("w", encoding="utf-8") as f:
        f.write("# Auto-generated by devtools/generate_release_parity_fixture.py\n")
        f.write("# Reference: QMCPy 2.3\n\n")
        f.write("const QMCPY23_RELEASE_PARITY = ")
        f.write(julia_literal(fixture))
        f.write("\n")


if __name__ == "__main__":
    main()
