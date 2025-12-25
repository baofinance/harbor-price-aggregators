# Off-Chain Market Data Extractor + Analytics Framework (Detailed Proposal)

## Why this exists

We maintain on-chain price/rate oracles for a small, explicit set of underlying markets. We want an off-chain system to:

1. collect historical market data for those markets (and future additions),
2. normalize it to a consistent representation,
3. enable charting and “market feel” exploration,
4. compute statistics and fit distributions for tail-risk intuition.

This document captures the full set of requirements and the concrete implementation options discussed, with pros/cons and recommendations.

## Requirements (complete)

### R1 — Data collection (off-chain)

- Collect **off-chain** historical market data for **all markets we have an on-chain version of**.
- Must include **daily close**.
- Preferably includes intraday-derived **daily min/max** (i.e., daily high/low) so we can analyze not only close-to-close returns but also intraday excursions.
- Must be easy to extend:
  - Add a **new market** to an existing feed (e.g., add a new trading pair / instrument).
  - Add a **new feed source/provider** (e.g., switch from one API to another, or add a second source for cross-checking).
- Must avoid “silent magic”: the data source, symbol mapping, and normalization rules must be explicit.

Additional requirement (resolved):

- Support **multiple sources per market** with a **single unified output**: the core of the system should treat the result as “one source” even if it is derived from multiple providers (selection and/or aggregation).

### R2 — Time semantics (day boundaries)

- Normalize everything to a canonical daily representation using **UTC day boundaries**.
- We must be able to define precisely what “daily close” means:
  - Provider daily candle close, or
  - derived from intraday candles (e.g., last price before UTC midnight).

### R3 — Analytics and visualization

The goal is to gain intuition and quantify tail behavior.

From normalized daily data, support:

- Long-horizon charts of daily closes (and optionally OHLC candles).
- Daily movement stats:
  - largest daily move using **close-to-close**
  - largest daily move taking into account **intraday high/low** (range/excursion)
- Distribution analysis:
  - plot distribution of daily moves
  - fit a distribution and estimate the probability of observing a given daily move
  - enable comparisons between fitted models (at least normal vs heavy-tailed)
- Rolling horizon moves:
  - weekly and monthly moves computed **on a rolling daily basis** (e.g. “rolling 7-day return” and “rolling 30-day return” in calendar time; or trading-day windows when appropriate)

Fail-fast behavior:

- Any analytics that require `high`/`low` must **fail explicitly** if those fields are missing for the market/source/date range.

### R4 — Tests (Python)

- Python tests in `tests/` using **pytest** (default).
- Tests must be deterministic:
  - avoid live API calls in unit tests
  - prefer fixtures/mocks or recorded cassettes

### R5 — Usability and maintainability

- Easy to run locally.
- Minimal moving parts.
- Dependencies managed via `uv` (update `pyproject.toml` + `uv.lock` together).
- Clear usage instructions, including “how to add a new feed/market.”

## Markets we currently care about (from on-chain config)

From [src/price/MainnetOracleAddresses.sol](../src/price/MainnetOracleAddresses.sol):

- Crypto: `ETH/USD`, `BTC/USD`, `stETH/USD`, `stETH/ETH`
- FX: `EUR/USD`
- Metals: `XAU/USD`
- Stablecoin: `USDC/USD`
- Index-like: `MCAP/USD` (provider-specific definition; needs explicit choice)

Important nuance:

- Some on-chain feeds (especially “index-like” ones) may not have a public off-chain dataset that matches the provider methodology exactly.
- The extractor should make “source of truth” explicit and allow swapping/adding sources.

## Definitions (what we will store)

### Canonical stored representation (recommended)

Store **daily OHLC** in **UTC**.

Minimum columns:

- `date` (UTC date, e.g. `2025-12-24`)
- `open`, `high`, `low`, `close` (float/decimal)
- `market` (normalized identifier; example: `ETH-USD`)
- `source` (provider identifier; example: `coinbase`)

Optional but useful:

- `volume` (where available)
- `currency`/`quote` metadata
- `provider_symbol` (the raw provider mapping for traceability)
- `timezone` (should always be UTC, but explicit metadata is useful)
- `granularity` (e.g. `1d`)

### Derived measures (examples)

Let $C_t$ be the daily close.

- Simple return:
  - $r_t = C_t / C_{t-1} - 1$
- Log return:
  - $\ell_t = \ln(C_t) - \ln(C_{t-1})$
- Intraday range ratio:
  - $\text{range}_t = H_t/L_t - 1$
- Intraday excursion vs previous close (one possible definition):
  - $\max(|H_t/C_{t-1}-1|, |L_t/C_{t-1}-1|)$

Recommendation:

- Store OHLC; compute all measures from it to avoid re-downloading.

## Where to get the data (detailed source options)

The key practical constraint is: daily high/low generally requires OHLC candles or intraday candles. “Official reference” series often only provide one number per day.

### Crypto markets: ETH/USD, BTC/USD, USDC/USD, stETH/USD, stETH/ETH

**Option C1 — Exchange OHLC (recommended baseline)**

- Example sources: Coinbase, Kraken, Binance.
- Pros:
  - Intraday and daily candles are first-class.
  - Daily min/max are directly available as high/low.
  - Usually stable APIs.
- Cons:
  - Close is exchange-specific and will differ from Chainlink aggregation.
  - Some markets may have limited liquidity/availability (esp. stETH pairs) depending on venue.

**Option C2 — Aggregators (CoinGecko / CryptoCompare)**

- Pros:
  - Convenient unified interfaces.
  - Better coverage for assets that are not strongly represented on one venue.
- Cons:
  - Rate limits and paid tiers.
  - Intraday coverage and exact definitions vary.

Recommendation:

- Start with one exchange source for ETH/BTC/USDC.
- For stETH markets, choose the best-coverage route (exchange pair if available; otherwise aggregator).

### FX/metals: EUR/USD, XAU/USD

Constraint (resolved):

- The initial implementation must use **no paid APIs**.

**Option F1 — Market data vendor OHLC (deferred)**

- Vendors: Twelve Data / Polygon.io / Tiingo / EODHD / Alpha Vantage.
- Pros:
  - Provides OHLC (so daily high/low exist).
  - More consistent than scraping.
- Cons:
  - Typically paid for reliable historical OHLC and/or intraday.
  - Adds key management + vendor lock-in.

**Option F2 — Free “reference rate” sources (ECB/FRED/LBMA)**

- Pros:
  - Stable and free.
- Cons:
  - Usually not OHLC (single daily fix/reference), so you lose min/max.

Recommendation:

- With “no paid APIs”, plan for **close-only** for EURUSD/XAUUSD in the initial implementation.
- Keep OHLC capability in the framework so upgrading to vendor OHLC later is a source swap, not a redesign.

### Market cap index: MCAP/USD

This is the hardest one to reproduce faithfully.

Design constraint:

- The `MCAP` choice must **not block initial implementation**. The system should cope with adding/changing feeds later.

**Option M1 — CoinGecko “total market cap”**

- Pros:
  - Conceptually aligned with “total crypto market cap”.
  - Often accessible without paid plans.
  - Good enough for exploratory analytics.
- Cons:
  - Methodology is provider-specific (constituents, free-float, stablecoin treatment).
  - Intraday granularity/high-low may be limited.
  - Historical gaps/limits may exist depending on endpoint.

**Option M2 — CoinMarketCap “global market cap”**

- Pros:
  - Also aligned and widely recognized.
  - May have better-defined endpoints depending on plan.
- Cons:
  - High-quality historical access is often paid.
  - “No paid APIs” makes this risky for the initial build.

**Option M3 — Derived index (compute market cap from constituents)**

- Idea: compute total market cap from a selected set of constituent assets using their market caps/price\*circulating supply.
- Pros:
  - Full control over definition.
  - Can make methodology explicit and auditable.
- Cons:
  - Significantly more complexity (constituent list management, supply sourcing, corporate actions-like issues).
  - Easy to accidentally build a bespoke index that is not comparable to on-chain feed.

Recommendation:

- Implement the framework so that `MCAP` is just another market with pluggable sources.
- For the initial implementation under “no paid APIs”, default to **CoinGecko** if it provides a reasonable free historical series.
- If CoinGecko’s free endpoints are insufficient, ship the framework without MCAP populated (explicitly) and add it later without changing core architecture.

## Implementation approaches (with pros/cons)

### A — Google Sheets

- Pros: quick manual exploration.
- Cons: not reproducible, not testable, fragile.
- Recommendation: no.

### B — Ad-hoc Python scripts

- Pros: quick to get a dataset.
- Cons: becomes unmaintainable; difficult to add markets/sources cleanly.
- Recommendation: ok for a spike only.

### C — Pluggable extractor framework (recommended)

Core ideas:

- A **Market** is a normalized identifier (e.g., `ETH-USD`), independent of providers.
- A **Source** is a provider adapter that knows how to fetch candles and map markets to provider symbols.
- A **Normalizer** converts provider output into canonical daily OHLC in UTC.

Why this fits the requirements:

- Adding a new market to an existing feed becomes adding a mapping + tests.
- Adding a new source is a new adapter implementing one interface.
- Analytics operates on canonical data; it doesn’t care where it came from.

### D — Add a DB engine (DuckDB)

- Pros: fast interactive queries, easy rolling-window stats.
- Cons: extra moving part.
- Recommendation: optional later; start file-based.

## Storage format (recommendation)

Requirement (resolved):

- The core should be able to output in **CSV or JSON** via an adapter.

### Parquet

- Pros:
  - Columnar + compressed: fast reads and small files for long histories.
  - Preserves types and missing values better than CSV.
  - Works well with pandas/polars/duckdb.
- Cons:
  - Requires `pyarrow` (heavier dependency).
  - Not human-readable.

### CSV

- Pros:
  - Human-readable, universally supported.
  - Easy to inspect diffs.
- Cons:
  - Slow and large for multi-market histories.
  - Type information is implicit; missing values are messy.
  - Less pleasant for downstream analytics at scale.

### JSON (export-only)

- Pros:
  - Useful for APIs and simple interchange.
- Cons:
  - Very large for time series; poor fit as canonical storage.

Recommendation:

- Use **Parquet as the canonical on-disk format**.
- Provide storage adapters to **export** the same normalized dataset to CSV and JSON.

## Framework shape (detailed)

### Proposed module boundaries (conceptual)

- `sources/` (provider adapters)
  - fetch raw candles
  - provider symbol mappings
  - rate limits / retry policy
- `aggregation/`
  - unify multiple sources into one market series
  - selection policy (priority / quorum)
  - aggregation policy (optional; e.g. median of available sources)
- `normalization/`
  - enforce UTC daily boundaries
  - resample intraday -> daily OHLC where needed
- `storage/`
  - cache (optional)
  - write/read parquet (canonical)
  - export adapters (csv/json)
- `analytics/`
  - returns, range, extreme moves
  - rolling weekly/monthly moves
  - distribution fitting and probability estimation
- `plotting/`
  - time series charts
  - distribution plots + fitted overlay

### CLI surface (what we want the user to run)

We discussed a CLI with at least:

- `extract`: download + normalize + store
- `stats`: compute summary statistics
- `plot`: chart price series and distributions

Examples (illustrative, not final):

- Extract daily candles for a market:
  - `python -m offchain_feeds extract --source coinbase --market ETH-USD --start 2017-01-01 --end 2025-12-24`
- Compute extremes:
  - `python -m offchain_feeds stats --market ETH-USD --measure close_return --top 20`
  - `python -m offchain_feeds stats --market ETH-USD --measure intraday_range --top 20`
- Plot distribution and fit:
  - `python -m offchain_feeds plot dist --market ETH-USD --measure log_return --fit normal --fit student_t`
- Rolling windows:
  - `python -m offchain_feeds stats rolling --market ETH-USD --window 7d`
  - `python -m offchain_feeds stats rolling --market ETH-USD --window 30d`

### Making it easy to add new markets/sources

We discussed two patterns:

**Pattern 1 — Code-first registry (recommended initially)**

- A registry maps `source_name -> adapter` and `market -> provider symbol`.
- Adding a market is a small code change + a fixture-based test.

**Pattern 2 — Config-driven markets (YAML/TOML)**

- Markets defined in config, adapters interpret them.
- More flexible for non-code additions but higher validation/complexity.

Recommendation:

- Start code-first; add config layer only once market taxonomy stabilizes.

## Testing approach (detailed)

### Unit tests (required)

Deterministic tests should cover:

- parsing of provider payloads
- symbol mapping
- UTC boundary correctness
- resampling intraday -> daily OHLC
- analytics computations:
  - returns
  - intraday range
  - rolling windows
  - distribution fitting sanity

### Avoiding live API flakiness

Options:

- Mock HTTP responses (fully deterministic)
- Record/replay (VCR-style) for “integration-ish” confidence without live calls

Recommendation:

- Start with mocked fixtures for unit tests.
- Optionally add a small recorded suite for one provider later.

## Distribution fitting (what we actually mean)

Goal: estimate how likely a given daily move is.

Minimum set of fitted models:

- Normal
- Student-t (heavy tails; usually more realistic for crypto)

Outputs to support:

- fitted parameters
- log-likelihood
- tail probability estimates, e.g. $P(|r| > x)$ for user-provided $x$

Visualization:

- histogram/KDE
- overlay fitted PDF
- (optional) QQ plot

Recommendation:

- Start with Normal vs Student-t; expand only if needed.

## Rolling weekly/monthly moves (what “weekly/monthly” means)

We need one convention per market class:

- Calendar windows (7d, 30d) applied to daily closes.
- Trading-day windows (5d, 21d) sometimes more standard for traditional assets.

Recommendation:

- Provide both window modes (calendar vs trading-day) as explicit options.

## Python tooling / packages (options)

We discussed likely dependencies (final selection depends on provider choices):

- Dataframes + IO:
  - pandas or polars
  - pyarrow (for parquet)
- HTTP:
  - httpx (or requests)
- Retry/backoff:
  - tenacity
- Stats:
  - numpy
  - scipy (distribution fitting)
- Plotting:
  - matplotlib (simple static) or plotly (interactive)
- Testing:
  - pytest
  - optionally respx (httpx mocking) or vcrpy (record/replay)

Recommendation:

- Prefer a small set initially: pandas/polars + pyarrow + httpx + tenacity + numpy + scipy + matplotlib + pytest.

## Recommendations (summary)

- Build a small pluggable framework (sources + normalization + storage + analytics + plotting).
- Store canonical daily OHLC in UTC (Parquet).
- Start with one primary provider per market class; allow extension.
- Use pytest with deterministic fixtures.
- Fit Normal vs Student-t for daily moves; compute tail probabilities.

## Open questions (still needed before coding)

Resolved:

1. Use **multiple sources per market**, unified via selection/aggregation so the core treats it like a single source.
2. Use **no paid APIs** in the initial implementation (expect close-only for some traditional markets initially).
3. Use **Parquet as canonical** with **CSV/JSON export adapters**.

Remaining (non-blocking):

3. `MCAP` provider: recommendation is **CoinGecko first** (free access is more plausible). If insufficient, ship framework without MCAP populated and add later as a new source.

## Next step

Once the open questions are answered, implement:

- extractor framework + CLI
- provider adapters for the chosen sources
- pytest suite
- dependency additions via `uv add` (updating `uv.lock` in the same change)
