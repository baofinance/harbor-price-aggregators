from __future__ import annotations

import dataclasses
import math
import pathlib
from typing import Any

import numpy as np
import pandas as pd
from arch import arch_model
from scipy import stats


@dataclasses.dataclass(frozen=True, slots=True)
class GarchFit:
    sigma: np.ndarray
    z: np.ndarray
    params: dict[str, float]


@dataclasses.dataclass(frozen=True, slots=True)
class InnovationFit:
    name: str
    params: dict[str, float]
    aic: float
    dist: Any  # scipy frozen distribution


def _mixture_quantile_model_return(
    *,
    sigma: np.ndarray,
    dist: Any,
    u: float,
) -> float:
    if not (0.0 < u < 1.0):
        raise ValueError("u must be in (0, 1)")

    sigma = np.asarray(sigma, dtype=float)
    sigma = sigma[np.isfinite(sigma) & (sigma > 0)]
    if sigma.size == 0:
        raise ValueError("sigma is empty")

    sigma_max = float(np.max(sigma))

    eps = 1e-12
    lo_q = max(eps, min(1.0 - eps, 1e-10))
    hi_q = max(eps, min(1.0 - eps, 1.0 - 1e-10))

    y_lo = float(dist.ppf(lo_q)) * sigma_max
    y_hi = float(dist.ppf(hi_q)) * sigma_max

    if not np.isfinite(y_lo) or not np.isfinite(y_hi) or y_lo >= y_hi:
        # Fall back to something wide based on observed sigma.
        y_lo = -10.0 * sigma_max
        y_hi = 10.0 * sigma_max

    y_grid = np.linspace(y_lo, y_hi, 5000, dtype=float)
    cdf = np.mean(dist.cdf(y_grid[:, None] / sigma[None, :]), axis=1)
    cdf = np.clip(cdf, 0.0, 1.0)
    cdf = np.maximum.accumulate(cdf)

    return float(np.interp(u, cdf, y_grid))


def _fit_garch11(returns: np.ndarray) -> GarchFit:
    if returns.ndim != 1:
        raise ValueError("returns must be 1D")

    x = returns.astype(float) * 100.0
    if not np.isfinite(x).all():
        raise ValueError("returns contain NaN/inf")

    if len(x) < 50:
        raise ValueError("Need at least 50 returns to fit GARCH")

    model = arch_model(x, mean="Zero", vol="GARCH", p=1, q=1, dist="normal", rescale=False)
    res = model.fit(disp="off")

    sigma = np.asarray(res.conditional_volatility, dtype=float) / 100.0
    z = np.asarray(res.std_resid, dtype=float)

    params = {k: float(v) for k, v in res.params.items()}
    return GarchFit(sigma=sigma, z=z, params=params)


def _fit_innovations(z: np.ndarray, *, family: str) -> InnovationFit:
    z = np.asarray(z, dtype=float)
    z = z[np.isfinite(z)]
    if len(z) < 50:
        raise ValueError("Need at least 50 standardized residuals to fit innovations")

    candidates: list[InnovationFit] = []

    def add_t() -> None:
        df, loc, scale = stats.t.fit(z)
        dist = stats.t(df, loc=loc, scale=scale)
        ll = float(np.sum(dist.logpdf(z)))
        k = 3
        aic = 2 * k - 2 * ll
        candidates.append(
            InnovationFit(
                name="student_t",
                params={"df": float(df), "loc": float(loc), "scale": float(scale)},
                aic=float(aic),
                dist=dist,
            )
        )

    def add_nig() -> None:
        a, b, loc, scale = stats.norminvgauss.fit(z)
        dist = stats.norminvgauss(a, b, loc=loc, scale=scale)
        ll = float(np.sum(dist.logpdf(z)))
        k = 4
        aic = 2 * k - 2 * ll
        candidates.append(
            InnovationFit(
                name="norminvgauss",
                params={"a": float(a), "b": float(b), "loc": float(loc), "scale": float(scale)},
                aic=float(aic),
                dist=dist,
            )
        )

    family = family.strip().lower()
    if family == "t":
        add_t()
    elif family == "nig":
        add_nig()
    elif family == "auto":
        add_t()
        add_nig()
    else:
        raise ValueError("family must be one of: auto, t, nig")

    return min(candidates, key=lambda c: c.aic)


def _fit_innovations_with_candidates(z: np.ndarray, *, family: str) -> tuple[InnovationFit, list[InnovationFit]]:
    z = np.asarray(z, dtype=float)
    z = z[np.isfinite(z)]
    if len(z) < 50:
        raise ValueError("Need at least 50 standardized residuals to fit innovations")

    candidates: list[InnovationFit] = []

    def add_t() -> None:
        df, loc, scale = stats.t.fit(z)
        dist = stats.t(df, loc=loc, scale=scale)
        ll = float(np.sum(dist.logpdf(z)))
        k = 3
        aic = 2 * k - 2 * ll
        candidates.append(
            InnovationFit(
                name="student_t",
                params={"df": float(df), "loc": float(loc), "scale": float(scale)},
                aic=float(aic),
                dist=dist,
            )
        )

    def add_nig() -> None:
        a, b, loc, scale = stats.norminvgauss.fit(z)
        dist = stats.norminvgauss(a, b, loc=loc, scale=scale)
        ll = float(np.sum(dist.logpdf(z)))
        k = 4
        aic = 2 * k - 2 * ll
        candidates.append(
            InnovationFit(
                name="norminvgauss",
                params={"a": float(a), "b": float(b), "loc": float(loc), "scale": float(scale)},
                aic=float(aic),
                dist=dist,
            )
        )

    family = family.strip().lower()
    if family == "t":
        add_t()
    elif family == "nig":
        add_nig()
    elif family == "auto":
        add_t()
        add_nig()
    else:
        raise ValueError("family must be one of: auto, t, nig")

    best = min(candidates, key=lambda c: c.aic)
    return best, candidates


def _to_model_return(simple_r: np.ndarray, *, kind: str) -> np.ndarray:
    if kind == "simple":
        return simple_r
    if kind == "log":
        return np.log1p(simple_r)
    raise ValueError("return kind must be 'simple' or 'log'")


def _jacobian_simple_to_model(simple_r: np.ndarray, *, kind: str) -> np.ndarray:
    if kind == "simple":
        return np.ones_like(simple_r, dtype=float)
    if kind == "log":
        # y = ln(1+x) => dy/dx = 1/(1+x)
        return 1.0 / (1.0 + simple_r)
    raise ValueError("return kind must be 'simple' or 'log'")


def fit_return_model(
    df: pd.DataFrame,
    *,
    return_kind: str,
    innovation_family: str,
    bucket_width: float,
    top_n: int,
    plot_path: pathlib.Path | None,
    print_buckets: bool,
    tail_masses: list[float] | None = None,
) -> tuple[dict[str, Any], pd.DataFrame, pd.DataFrame | None]:
    if bucket_width <= 0:
        raise ValueError("bucket_width must be > 0")
    if top_n <= 0:
        raise ValueError("top_n must be > 0")

    df = df.copy().sort_values(["date"], kind="stable").reset_index(drop=True)
    df["prev_close"] = df["close"].shift(1)
    df = df.dropna(subset=["prev_close"]).reset_index(drop=True)
    if df.empty:
        raise ValueError("Need at least 2 closes to compute returns")

    simple_r = (df["close"] / df["prev_close"] - 1.0).astype(float).to_numpy()
    if not np.isfinite(simple_r).all():
        raise ValueError("Computed returns contain NaN/inf")

    model_r = _to_model_return(simple_r, kind=return_kind)

    garch = _fit_garch11(model_r)
    sigma = garch.sigma
    z = garch.z

    innov, candidates = _fit_innovations_with_candidates(z, family=innovation_family)
    dist = innov.dist

    # Per-observation metrics.
    cdf = dist.cdf(z)
    cdf = np.clip(cdf, 0.0, 1.0)

    p_one_sided = np.where(model_r >= 0, 1.0 - cdf, cdf)
    p_two_sided = 2.0 * np.minimum(cdf, 1.0 - cdf)

    # Conditional density of model return.
    density_model_r = dist.pdf(z) / sigma

    # Bucket probability in SIMPLE-return space.
    bucket_low = np.floor(simple_r / bucket_width) * bucket_width
    bucket_high = bucket_low + bucket_width

    bucket_low_model = _to_model_return(bucket_low, kind=return_kind)
    bucket_high_model = _to_model_return(bucket_high, kind=return_kind)

    p_bucket = dist.cdf(bucket_high_model / sigma) - dist.cdf(bucket_low_model / sigma)
    p_bucket = np.clip(p_bucket, 0.0, 1.0)

    out = pd.DataFrame(
        {
            "date": df["date"].to_numpy(),
            "close": df["close"].to_numpy(dtype=float),
            "return": simple_r,
            "return_model": model_r,
            "sigma": sigma,
            "z": z,
            "p_one_sided": p_one_sided,
            "p_two_sided": p_two_sided,
            "pdf_density": density_model_r,
            "bucket_low": bucket_low,
            "bucket_high": bucket_high,
            "p_bucket": p_bucket,
        }
    )

    top = out.sort_values(["p_two_sided"], ascending=True, kind="stable").head(top_n).reset_index(drop=True)

    buckets_df: pd.DataFrame | None = None
    if print_buckets:
        lo = float(math.floor(float(np.min(simple_r)) / bucket_width) * bucket_width)
        hi = float(math.ceil(float(np.max(simple_r)) / bucket_width) * bucket_width)
        edges = np.arange(lo, hi + bucket_width, bucket_width, dtype=float)
        if len(edges) >= 2:
            lows = edges[:-1]
            highs = edges[1:]

            lows_m = _to_model_return(lows, kind=return_kind)
            highs_m = _to_model_return(highs, kind=return_kind)

            # Mixture probability across time: average of conditional bucket probs.
            probs = np.mean(
                dist.cdf(highs_m[:, None] / sigma[None, :]) - dist.cdf(lows_m[:, None] / sigma[None, :]), axis=1
            )
            probs = np.clip(probs, 0.0, 1.0)

            # Empirical frequencies.
            emp, _ = np.histogram(simple_r, bins=edges)
            emp_prob = emp / float(len(simple_r))

            buckets_df = pd.DataFrame(
                {
                    "bucket_low": lows,
                    "bucket_high": highs,
                    "prob_fitted": probs,
                    "prob_empirical": emp_prob,
                }
            )

    if plot_path is not None:
        # Local import to keep import-time side effects small.
        import matplotlib

        matplotlib.use("Agg")
        import matplotlib.pyplot as plt

        fig, (ax_r, ax_z) = plt.subplots(1, 2, figsize=(12, 4))

        # Plot 1: raw (simple) returns histogram with mixture density overlay.
        ax_r.hist(simple_r * 100.0, bins=60, density=True, alpha=0.6)

        x = np.linspace(float(np.min(simple_r)), float(np.max(simple_r)), 400)
        y_model = _to_model_return(x, kind=return_kind)
        jac = _jacobian_simple_to_model(x, kind=return_kind)

        mix_density_model = np.mean(dist.pdf(y_model[:, None] / sigma[None, :]) / sigma[None, :], axis=1)
        mix_density_simple = mix_density_model * jac

        ax_r.plot(x * 100.0, mix_density_simple)
        ax_r.set_title("Close-to-close returns (simple)")
        ax_r.set_xlabel("return (%)")
        ax_r.set_ylabel("density")

        # Plot 2: standardized residuals (z) with fitted innovations curve.
        ax_z.hist(z, bins=60, density=True, alpha=0.6)
        zz = np.linspace(float(np.min(z)), float(np.max(z)), 400)
        ax_z.plot(zz, dist.pdf(zz))
        ax_z.set_title(f"GARCH std residuals fit: {innov.name}")
        ax_z.set_xlabel("z")
        ax_z.set_ylabel("density")

        plot_path.parent.mkdir(parents=True, exist_ok=True)
        fig.tight_layout()
        fig.savefig(plot_path, dpi=150)
        plt.close(fig)

    meta: dict[str, Any] = {
        "return_kind": return_kind,
        "garch": {"model": "GARCH(1,1)", "mean": "Zero", "dist": "normal", "params": garch.params},
        "innovations": {
            "family": innov.name,
            "aic": innov.aic,
            "params": innov.params,
            "candidates": [
                {"family": c.name, "aic": c.aic, "params": c.params} for c in sorted(candidates, key=lambda c: c.aic)
            ],
        },
        "bucket_width": bucket_width,
    }

    if tail_masses:
        intervals = []
        for p in tail_masses:
            p = float(p)
            if not (0.0 < p < 1.0):
                raise ValueError("tail mass must be in (0, 1)")

            u_lo = p / 2.0
            u_hi = 1.0 - p / 2.0

            y_lo = _mixture_quantile_model_return(sigma=sigma, dist=dist, u=u_lo)
            y_hi = _mixture_quantile_model_return(sigma=sigma, dist=dist, u=u_hi)

            if return_kind == "log":
                x_lo = float(np.expm1(y_lo))
                x_hi = float(np.expm1(y_hi))
            else:
                x_lo = float(y_lo)
                x_hi = float(y_hi)

            intervals.append({"tail_mass": p, "lower_simple": x_lo, "upper_simple": x_hi})

        meta["two_sided_tail_mass_intervals"] = intervals

    return meta, top, buckets_df
