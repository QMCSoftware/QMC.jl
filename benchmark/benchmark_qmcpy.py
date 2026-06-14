#!/usr/bin/env python3
"""QMCPy benchmark harness — Python counterpart of benchmark/benchmarks.jl.

Mirrors the Julia `SUITE` so results can be compared case-by-case against
benchmark/results/latest.json (from `make bench`). Run with the QMCPy that the
Julia package was translated from:

    pip install qmcpy            # or put QMCSoftware/ on PYTHONPATH
    python benchmark/benchmark_qmcpy.py
    python benchmark/benchmark_qmcpy.py mylabel   # -> results/qmcpy_mylabel.json

IMPORTANT — what is and isn't a language comparison
---------------------------------------------------
* `gen_samples` for Lattice / DigitalNetB2 / Halton calls the SAME `qmctoolscl`
  C library in both packages. Those rows compare the C kernel + FFI binding, not
  Julia vs Python. Tagged [C] below.
* IIDStdUniform / Kronecker generation, `transform`, and `evaluate` are pure
  Python/numpy vs pure Julia — those are the honest language comparisons.
* `integrate` mixes both (generator + transform + evaluate + algorithm glue).

Method parity with the Julia suite
----------------------------------
* gen_samples  : dd(n)                              ~ gen_samples(dd, n)
* transform    : Gaussian(dd)._transform(x)         ~ transform(tm, x)
* evaluate     : integrand.g(t)                     ~ evaluate(f, x)   (t = transformed points)
* integrate    : sc.integrate()                     ~ integrate(sc)

Caveats: QMCPy's Genz supports only OSCILLATORY / CORNER PEAK, so the benchmark
rows for Julia's extra Genz kinds (GAUSSIAN PEAK / CONTINUOUS) use small direct
NumPy implementations with the same default parameters. QMCPy's FinancialOption
wraps the sampler directly (option="ASIAN"/"EUROPEAN") and builds its GBM
internally, whereas the Julia version wraps a GeometricBrownianMotion measure;
the end-to-end problem is the same. Timing here uses wall-clock medians; Python
has no direct allocation count, so only the time column is cross-comparable with
the Julia ms column.
"""

import sys
import json
import gc
import os
import subprocess
import timeit
import tracemalloc
import warnings
import statistics
from datetime import datetime
from pathlib import Path

import numpy as np
import qmcpy as qp

# Mirror the Julia configuration.
SAMPLES = [256, 1024, 4096, 16384]
DIMS = [3, 10]
LARGE_DIMS = [50, 200]
LARGE_N = [1024, 4096]
SEED = 42
DEFAULT_REPEAT = 7
INTEGRATE_REPEAT = 9
STUDENT_T_REPEAT = 21
STUDENT_T_WARMUP_RUNS = 3
THREAD_ENV_KEYS = (
    "QMC_BENCH_BLAS_THREADS",
    "OPENBLAS_NUM_THREADS",
    "MKL_NUM_THREADS",
    "OMP_NUM_THREADS",
    "NUMEXPR_NUM_THREADS",
)


def current_rss_kib():
    """Best-effort current process RSS in KiB, or None if unavailable."""
    try:
        out = subprocess.check_output(
            ["ps", "-o", "rss=", "-p", str(os.getpid())],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
        return float(out)
    except Exception:  # noqa: BLE001 - memory telemetry is best effort
        return None


def measure_memory(fn):
    """Return approximate Python memory metrics for one warmed call."""
    gc.collect()
    rss_before = current_rss_kib()
    tracemalloc.start()
    try:
        fn()
        _, peak = tracemalloc.get_traced_memory()
    finally:
        tracemalloc.stop()
    rss_after = current_rss_kib()
    gc.collect()

    metrics = {"tracemalloc_peak_kib": peak / 1024.0}
    if rss_before is not None and rss_after is not None:
        # Retained RSS delta after the call, not peak RSS during the call.
        metrics["rss_delta_kib"] = max(rss_after - rss_before, 0.0)
    return metrics


def bench(make_call, *, repeat=DEFAULT_REPEAT, warmup=True):
    """Return median seconds plus approximate memory metrics per call."""
    if isinstance(warmup, bool):
        warmup_runs = 1 if warmup else 0
    else:
        warmup_runs = int(warmup)
        if warmup_runs < 0:
            raise ValueError("warmup must be bool or non-negative integer")
    fn = make_call()
    for _ in range(warmup_runs):
        fn()  # discard first call(s) to reduce cache/allocation warm-up noise
    mem = measure_memory(fn)
    # Pick an inner count so each timing sample is long enough to be stable.
    timer = timeit.Timer(fn)
    count, _ = timer.autorange()
    samples = timer.repeat(repeat=repeat, number=count)
    return statistics.median(samples) / count, mem


def dense_covariance(dim):
    cov = np.full((dim, dim), 0.5)
    np.fill_diagonal(cov, 1.0)
    return cov


def genz_gaussian_peak(x):
    shifted = x - 0.5
    return np.exp(-np.sum(shifted * shifted, axis=1))


def genz_continuous(x):
    return np.exp(-np.sum(np.abs(x - 0.5), axis=1))


def record(results, group, name, make_call, **kw):
    try:
        secs, mem = bench(make_call, **kw)
        results[group][name] = {"median_ms": secs * 1e3, **mem}
        rss_msg = ""
        if "rss_delta_kib" in mem:
            rss_msg = f", rss Δ {mem['rss_delta_kib']:.1f} KiB"
        print(
            f"  {name:<45s}  {secs * 1e3:10.3f} ms"
            f"  (py peak {mem['tracemalloc_peak_kib']:.1f} KiB{rss_msg})"
        )
    except Exception as e:  # noqa: BLE001 - keep one bad case from aborting the run
        results[group][name] = {"error": f"{type(e).__name__}: {e}"}
        print(f"  {name:<45s}  ERR: {type(e).__name__}: {e}")


def active_thread_env():
    return {key: os.environ[key] for key in THREAD_ENV_KEYS if key in os.environ}


def main():
    label = sys.argv[1] if len(sys.argv) > 1 else "latest"
    results = {"gen_samples": {}, "transform": {}, "evaluate": {}, "integrate": {}}

    print("\n\nQMCPy Benchmarks (qmcpy %s)" % getattr(qp, "__version__", "?"))
    print("=" * 70)
    thread_env = active_thread_env()
    if thread_env:
        print(
            "Thread env: "
            + ", ".join(f"{key}={value}" for key, value in sorted(thread_env.items()))
        )
    print(
        f"StudentT config: repeat={STUDENT_T_REPEAT}, warmup_runs={STUDENT_T_WARMUP_RUNS}"
    )

    # 1. Discrete distribution sampling --------------------------------------
    # [C] = qmctoolscl C kernel (not a language comparison)
    print("\n-- gen_samples --")
    for dim in DIMS:
        for n in SAMPLES:
            record(results, "gen_samples", f"IIDStdUniform d={dim} n={n}",
                   lambda dim=dim, n=n: (lambda dd=qp.IIDStdUniform(dim, seed=SEED): (lambda: dd(n)))())
            record(results, "gen_samples", f"Lattice [C] d={dim} n={n}",
                   lambda dim=dim, n=n: (lambda dd=qp.Lattice(dim, seed=SEED): (lambda: dd(n)))())
            record(results, "gen_samples", f"DigitalNetB2 [C] d={dim} n={n}",
                   lambda dim=dim, n=n: (lambda dd=qp.DigitalNetB2(dim, seed=SEED): (lambda: dd(n)))())
            record(results, "gen_samples", f"Halton [C] d={dim} n={n}",
                   lambda dim=dim, n=n: (lambda dd=qp.Halton(dim, seed=SEED): (lambda: dd(n)))())
            record(results, "gen_samples", f"Kronecker d={dim} n={n}",
                   lambda dim=dim, n=n: (lambda dd=qp.Kronecker(dim, seed=SEED): (lambda: dd(n)))())

    # 2. Transform (pure numpy: inverse-CDF + covariance factor) --------------
    print("\n-- transform --")
    for dim in DIMS:
        for n in SAMPLES:
            def make_transform(dim=dim, n=n):
                dd = qp.IIDStdUniform(dim, seed=SEED)
                tm = qp.Gaussian(dd)
                x = dd(n)
                return lambda: tm._transform(x)
            record(results, "transform", f"Gaussian d={dim} n={n}", make_transform)

    for dim in LARGE_DIMS:
        for n in LARGE_N:
            def make_gaussian_diag(dim=dim, n=n):
                dd = qp.IIDStdUniform(dim, seed=SEED)
                tm = qp.Gaussian(dd)
                x = dd(n)
                return lambda: tm._transform(x)
            record(results, "transform", f"Gaussian(diag) d={dim} n={n}", make_gaussian_diag)

            def make_gaussian_dense(dim=dim, n=n):
                dd = qp.IIDStdUniform(dim, seed=SEED)
                tm = qp.Gaussian(dd, covariance=dense_covariance(dim))
                x = dd(n)
                return lambda: tm._transform(x)
            record(results, "transform", f"Gaussian(dense) d={dim} n={n}", make_gaussian_dense)

    for n in SAMPLES:
        def make_student_t(n=n):
            dim = 10
            dd = qp.IIDStdUniform(dim, seed=SEED)
            tm = qp.StudentT(dd, loc=np.zeros(dim), shape=np.eye(dim), df=2.0)
            x = dd(n)
            return lambda: tm._transform(x)
        record(
            results,
            "transform",
            f"StudentT d=10 n={n}",
            make_student_t,
            repeat=STUDENT_T_REPEAT,
            warmup=STUDENT_T_WARMUP_RUNS,
        )

        def make_johnsons_su(n=n):
            dim = 10
            dd = qp.IIDStdUniform(dim, seed=SEED)
            tm = qp.JohnsonsSU(dd, gamma=0.0, xi=0.0, delta=1.0, lam=1.0)
            x = dd(n)
            return lambda: tm._transform(x)
        record(results, "transform", f"JohnsonsSU d=10 n={n}", make_johnsons_su)

    # 3. Integrand evaluation (pure numpy) -----------------------------------
    print("\n-- evaluate --")
    for n in SAMPLES:
        def make_keister(n=n):
            dd = qp.IIDStdUniform(3, seed=SEED)
            f = qp.Keister(dd)
            t = f.true_measure._transform(dd(n))
            return lambda: f.g(t)
        record(results, "evaluate", f"Keister n={n}", make_keister)

        def make_genz(n=n):
            dd = qp.IIDStdUniform(3, seed=SEED)
            f = qp.Genz(dd, kind_func="OSCILLATORY")
            t = f.true_measure._transform(dd(n))
            return lambda: f.g(t)
        record(results, "evaluate", f"Genz(oscillatory) n={n}", make_genz)

    for n in SAMPLES:
        def make_box(n=n):
            dim = 10
            dd = qp.IIDStdUniform(dim, seed=SEED)
            f = qp.BoxIntegral(dd)
            x = dd(n)
            return lambda: f.g(x)
        record(results, "evaluate", f"BoxIntegral d=10 n={n}", make_box)

        def make_linear0(n=n):
            dim = 10
            dd = qp.IIDStdUniform(dim, seed=SEED)
            f = qp.Linear0(dd)
            x = dd(n)
            return lambda: f.g(x)
        record(results, "evaluate", f"Linear0 d=10 n={n}", make_linear0)

        def make_genz_gaussian_peak(n=n):
            dim = 10
            dd = qp.IIDStdUniform(dim, seed=SEED)
            x = dd(n)
            return lambda: genz_gaussian_peak(x)
        record(results, "evaluate", f"Genz(gaussian_peak) d=10 n={n}", make_genz_gaussian_peak)

        def make_genz_continuous(n=n):
            dim = 10
            dd = qp.IIDStdUniform(dim, seed=SEED)
            x = dd(n)
            return lambda: genz_continuous(x)
        record(results, "evaluate", f"Genz(continuous) d=10 n={n}", make_genz_continuous)

    for dim in LARGE_DIMS:
        for n in LARGE_N:
            def make_box_large(dim=dim, n=n):
                dd = qp.IIDStdUniform(dim, seed=SEED)
                f = qp.BoxIntegral(dd)
                x = dd(n)
                return lambda: f.g(x)
            record(results, "evaluate", f"BoxIntegral d={dim} n={n}", make_box_large)

            def make_linear0_large(dim=dim, n=n):
                dd = qp.IIDStdUniform(dim, seed=SEED)
                f = qp.Linear0(dd)
                x = dd(n)
                return lambda: f.g(x)
            record(results, "evaluate", f"Linear0 d={dim} n={n}", make_linear0_large)

            def make_genz_gaussian_peak_large(dim=dim, n=n):
                dd = qp.IIDStdUniform(dim, seed=SEED)
                x = dd(n)
                return lambda: genz_gaussian_peak(x)
            record(results, "evaluate", f"Genz(gaussian_peak) d={dim} n={n}", make_genz_gaussian_peak_large)

    # 4. End-to-end integration ----------------------------------------------
    print("\n-- integrate --")

    def integrate_call(make_sc):
        def factory():
            def run():
                with warnings.catch_warnings():
                    warnings.simplefilter("ignore")
                    return make_sc().integrate()
            return run
        return factory

    def _scalar(x):
        # QMCPy may return solution/tolerances as 0-d or 1-element arrays.
        return float(np.asarray(x).ravel()[0])

    # (name, make_sc, warmup). make_sc builds a fresh stopping criterion; it is
    # reused both for timing and for the one-shot accuracy measurement below.
    # Julia's default `CubQMCNetG` now matches QMCPy's single-net `CubQMCNetG`
    # directly. The Julia-only replicated companion `CubQMCNetGRep` is omitted
    # here and will therefore show `n/a` in cross-language reports.
    integrate_cases = [
        ("CubMCCLT Keister",
         lambda: qp.CubMCCLT(qp.Keister(qp.IIDStdUniform(3, seed=SEED)), abs_tol=0.01),
         True),
        ("CubQMCLatticeG Keister",
         lambda: qp.CubQMCLatticeG(qp.Keister(qp.Lattice(3, seed=SEED)), abs_tol=0.01),
         False),
        ("CubQMCNetG Keister",
         lambda: qp.CubQMCNetG(qp.Keister(qp.DigitalNetB2(3, seed=SEED)), abs_tol=0.01),
         False),
        ("CubMCCLT AsianOption",
         lambda: qp.CubMCCLT(
             qp.FinancialOption(qp.IIDStdUniform(50, seed=SEED), option="ASIAN",
                                volatility=0.2, start_price=100, strike_price=100,
                                interest_rate=0.05, t_final=1), abs_tol=0.5),
         False),
        ("CubQMCNetG EuropeanOption",
         lambda: qp.CubQMCNetG(
             qp.FinancialOption(qp.DigitalNetB2(50, seed=SEED), option="EUROPEAN",
                                volatility=0.2, start_price=100, strike_price=100,
                                interest_rate=0.05, t_final=1), abs_tol=0.5),
         False),
        ("CubMCCLT EuropeanOption",
         lambda: qp.CubMCCLT(
             qp.FinancialOption(qp.IIDStdUniform(50, seed=SEED), option="EUROPEAN",
                                volatility=0.2, start_price=100, strike_price=100,
                                interest_rate=0.05, t_final=1), abs_tol=0.5),
         False),
        ("CubQMCLatticeG EuropeanOption",
         lambda: qp.CubQMCLatticeG(
             qp.FinancialOption(qp.Lattice(50, seed=SEED), option="EUROPEAN",
                                volatility=0.2, start_price=100, strike_price=100,
                                interest_rate=0.05, t_final=1), abs_tol=0.5),
         False),
        ("CubQMCNetG AsianOption",
         lambda: qp.CubQMCNetG(
             qp.FinancialOption(qp.DigitalNetB2(50, seed=SEED), option="ASIAN",
                                volatility=0.2, start_price=100, strike_price=100,
                                interest_rate=0.05, t_final=1), abs_tol=0.5),
         False),
        # Replication + Student-t cubature. QMCPy's CubQMCRepStudentT is the analog
        # of Julia's CubQMCNetGRep: it averages `replications` independently
        # randomized digital nets and stops on a Student-t half-width across the
        # replication means. n_reps=16 matches the Julia default.
        ("CubQMCNetGRep Keister",
         lambda: qp.CubQMCRepStudentT(
             qp.Keister(qp.DigitalNetB2(3, seed=SEED, replications=16)), abs_tol=0.01),
         False),
        ("CubQMCNetGRep EuropeanOption",
         lambda: qp.CubQMCRepStudentT(
             qp.FinancialOption(qp.DigitalNetB2(50, seed=SEED, replications=16), option="EUROPEAN",
                                volatility=0.2, start_price=100, strike_price=100,
                                interest_rate=0.05, t_final=1), abs_tol=0.5),
         False),
        ("CubQMCNetGRep AsianOption",
         lambda: qp.CubQMCRepStudentT(
             qp.FinancialOption(qp.DigitalNetB2(50, seed=SEED, replications=16), option="ASIAN",
                                volatility=0.2, start_price=100, strike_price=100,
                                interest_rate=0.05, t_final=1), abs_tol=0.5),
         False),
    ]

    for name, make_sc, warm in integrate_cases:
        record(results, "integrate", name, integrate_call(make_sc),
               repeat=INTEGRATE_REPEAT, warmup=warm)
        # One-shot accuracy measurement: solution value + tolerances used. Kept
        # separate from the timed runs and never aborts the run on failure.
        try:
            with warnings.catch_warnings():
                warnings.simplefilter("ignore")
                sc = make_sc()
                solution, _ = sc.integrate()
            entry = results["integrate"].get(name)
            if isinstance(entry, dict) and "error" not in entry:
                entry["solution"] = _scalar(solution)
                entry["abs_tol"] = _scalar(getattr(sc, "abs_tol", 0.0))
                entry["rel_tol"] = _scalar(getattr(sc, "rel_tol", 0.0))
        except Exception as e:  # noqa: BLE001
            print(f"  (accuracy) {name:<35s} skipped: {type(e).__name__}: {e}")

    # ── Save ─────────────────────────────────────────────────────────────
    resdir = Path(__file__).resolve().parent / "results"
    resdir.mkdir(exist_ok=True)
    outfile = resdir / f"qmcpy_{label}.json"
    payload = {
        "qmcpy_version": getattr(qp, "__version__", "?"),
        "python_version": sys.version.split()[0],
        "label": label,
        "generated_at": datetime.now().isoformat(timespec="seconds"),
        "thread_env": thread_env,
        "benchmark_config": {
            "default_repeat": DEFAULT_REPEAT,
            "integrate_repeat": INTEGRATE_REPEAT,
            "student_t_repeat": STUDENT_T_REPEAT,
            "student_t_warmup_runs": STUDENT_T_WARMUP_RUNS,
        },
        "results": results,
    }
    outfile.write_text(json.dumps(payload, indent=2))
    print(f"\nResults saved to benchmark/results/qmcpy_{label}.json")


if __name__ == "__main__":
    main()
