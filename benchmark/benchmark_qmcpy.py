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

Caveats: QMCPy's Genz supports only OSCILLATORY / CORNER PEAK (the Julia suite is
set to :oscillatory to match). QMCPy's FinancialOption wraps the sampler directly
(option="ASIAN"/"EUROPEAN") and builds its GBM internally, whereas the Julia
version wraps a GeometricBrownianMotion measure; the end-to-end problem is the
same. Timing here uses wall-clock medians; Python has no direct allocation count,
so only the time column is cross-comparable with the Julia ms column.
"""

import sys
import json
import timeit
import warnings
import statistics
from pathlib import Path

import numpy as np
import qmcpy as qp

# Mirror the Julia configuration.
SAMPLES = [256, 1024, 4096, 16384]
DIMS = [3, 10]
SEED = 42


def bench(make_call, *, repeat=7, warmup=True):
    """Return median seconds per call. `make_call` returns a zero-arg callable."""
    fn = make_call()
    if warmup:
        fn()  # discard first call (cache/allocation warm-up)
    # Pick an inner count so each timing sample is long enough to be stable.
    timer = timeit.Timer(fn)
    count, _ = timer.autorange()
    samples = timer.repeat(repeat=repeat, number=count)
    return statistics.median(samples) / count


def record(results, group, name, make_call, **kw):
    try:
        secs = bench(make_call, **kw)
        results[group][name] = {"median_ms": secs * 1e3}
        print(f"  {name:<45s}  {secs * 1e3:10.3f} ms")
    except Exception as e:  # noqa: BLE001 - keep one bad case from aborting the run
        results[group][name] = {"error": f"{type(e).__name__}: {e}"}
        print(f"  {name:<45s}  ERR: {type(e).__name__}: {e}")


def main():
    label = sys.argv[1] if len(sys.argv) > 1 else "latest"
    results = {"gen_samples": {}, "transform": {}, "evaluate": {}, "integrate": {}}

    print("QMCPy Benchmarks (qmcpy %s)" % getattr(qp, "__version__", "?"))
    print("=" * 70)

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

    record(results, "integrate", "CubMCCLT Keister",
           integrate_call(lambda: qp.CubMCCLT(qp.Keister(qp.IIDStdUniform(3, seed=SEED)), abs_tol=0.01)),
           repeat=3, warmup=True)
    record(results, "integrate", "CubQMCLatticeG Keister",
           integrate_call(lambda: qp.CubQMCLatticeG(qp.Keister(qp.Lattice(3, seed=SEED)), abs_tol=0.01)),
           repeat=3)
    record(results, "integrate", "CubQMCNetG Keister",
           integrate_call(lambda: qp.CubQMCNetG(qp.Keister(qp.DigitalNetB2(3, seed=SEED)), abs_tol=0.01)),
           repeat=3)
    record(results, "integrate", "CubMCCLT AsianOption",
           integrate_call(lambda: qp.CubMCCLT(
               qp.FinancialOption(qp.IIDStdUniform(50, seed=SEED), option="ASIAN",
                                  volatility=0.2, start_price=100, strike_price=100,
                                  interest_rate=0.05, t_final=1), abs_tol=0.5)),
           repeat=3)
    record(results, "integrate", "CubQMCNetG EuropeanOption",
           integrate_call(lambda: qp.CubQMCNetG(
               qp.FinancialOption(qp.DigitalNetB2(50, seed=SEED), option="EUROPEAN",
                                  volatility=0.2, start_price=100, strike_price=100,
                                  interest_rate=0.05, t_final=1), abs_tol=0.5)),
           repeat=3)

    # ── Save ─────────────────────────────────────────────────────────────
    resdir = Path(__file__).resolve().parent / "results"
    resdir.mkdir(exist_ok=True)
    outfile = resdir / f"qmcpy_{label}.json"
    payload = {
        "qmcpy_version": getattr(qp, "__version__", "?"),
        "results": results,
    }
    outfile.write_text(json.dumps(payload, indent=2))
    print(f"\nResults saved to benchmark/results/qmcpy_{label}.json")


if __name__ == "__main__":
    main()
