# SPCX/USD goes stale every weekend, and two deployed oracles revert with it

`Aggregator_fxUSD_SPCX_mainnet` and `Aggregator_stETH_SPCX_mainnet` revert `StaleFeedData` from
roughly 24 hours after the US market closes on Friday until it reopens on Monday — about **41 hours
every weekend**, and about **65 hours** when the Monday is a public holiday. Both are deployed.

This is not a test failure. It is reproducible against the deployed contracts themselves:

| | address |
|---|---|
| `Aggregator_fxUSD_SPCX_mainnet` | `0x2EFe29a59C0E2330F06DCB18F70602C3875855d1` |
| `Aggregator_stETH_SPCX_mainnet` | `0x22708015318eBa553EE596Fb56786a7aD7133217` |

```bash
cast call 0x2EFe29a59C0E2330F06DCB18F70602C3875855d1 \
  "latestAnswer()(uint256,uint256,uint256,uint256)" --block 25926463 --rpc-url mainnet
# Error: execution reverted: StaleFeedData(0x0a585B784513AB053563deE3CF830c633e4ff6c7, ...)
```

## The cause

`src/feeds/chainlink/mainnet/SPCX_USD.sol` declares

```solidity
/// @notice Heartbeat: 24 hours (86400 seconds)
/// @dev Equity-style feed; updates at least once per heartbeat or on deviation
uint256 internal constant HEARTBEAT = 86400;
```

**SPCX/USD does not provide that guarantee.** Its updates are deviation-driven *within the US equity
session only*. Outside the session it posts nothing at all — no heartbeat round, no repeat of the last
price.

Its sibling feeds do provide it, which is why only SPCX is affected. Measured over 119 rounds read
straight from the aggregators (method below):

| feed | outside market hours | largest gap | overshoot beyond 86400 |
|---|---|---|---|
| `AAPL/USD` (arbitrum) | posts a heartbeat round every 24h | 24.0 h | **14 s** |
| `STRC/USD` (mainnet) | posts a heartbeat round every 24h | 24.0 h | **24 s** |
| **`SPCX/USD` (mainnet)** | **posts nothing** | **89.6 h** | **65.6 h** |

`ChainlinkFeedLib.HEARTBEAT_TOLERANCE = 42` seconds exists for exactly the 14–24 second late-landing
that AAPL and STRC show, and it absorbs them. Nothing can absorb an absence of 65.6 hours.

SPCX's observed pattern is unambiguous. Every session begins at **exactly 13:30 UTC** (09:30 ET, market
open) and the last round of the day lands between 19:20 and 19:57 UTC (≈15:20–15:57 ET, just before
the 16:00 ET close). Overnight gaps run 17.6–18.2 h, comfortably inside the heartbeat, which is why
weekdays pass and the problem is invisible in a weekday CI run.

```
Thu 03 Sep 19:57 -> Fri 04 Sep 13:30  =  17.6 h
Fri 04 Sep 19:53 -> Tue 08 Sep 13:30  =  89.6 h   <- Labor Day weekend
Tue 08 Sep 19:33 -> Wed 09 Sep 13:30  =  17.9 h
Wed 09 Sep 19:29 -> Thu 10 Sep 13:30  =  18.0 h
Thu 10 Sep 19:20 -> Fri 11 Sep 13:30  =  18.2 h
```

A normal weekend is Friday ≈19:50 → Monday 13:30 = **65.7 h**. The heartbeat is missed every single
week.

## How to reproduce it

**From the pinned test.** `test/mainnet/SpcxWeekendOutageFork.t.sol`
(`SpcxWeekendOutageForkTest`) is pinned at block **25926463** (Mon 07 Sep 2026 15:46 UTC — Labor Day).
Its two tests

- `test_fork_fxUSD_SPCX_answersWhileTheMarketIsShut`
- `test_fork_stETH_SPCX_answersWhileTheMarketIsShut`

both carry `vm.skip(true)`. **They are the acceptance test for the fix**: remove the skip and they
must pass. Today they fail with

```
StaleFeedData(0x0a585B784513AB053563deE3CF830c633e4ff6c7, 1788551639, 1788796007, 86400)
```

The four arguments are the feed, its `updatedAt` (Fri 04 Sep 19:53 UTC), the block timestamp
(Mon 07 Sep 15:46 UTC) and the configured heartbeat. The gap is 67.9 h against a 24 h bound.

**From the chain directly**, which is how the table above was produced. The proxy's round id encodes
the phase in its high 64 bits, so walk it back in Python rather than in bash — 2^64 overflows bash's
signed arithmetic and silently queries nonsense:

```bash
FEED=0x0a585B784513AB053563deE3CF830c633e4ff6c7
RID=$(cast call "$FEED" "latestRoundData()(uint80,int256,uint256,uint256,uint80)" \
        --rpc-url mainnet | sed -n '1p' | sed 's/ .*//')
python3 -c "
rid=$RID; phase=rid>>64; rnd=rid-(phase<<64)
for r in range(rnd, rnd-120, -1): print((phase<<64)+r)
" | while read -r id; do
  cast call "$FEED" "getRoundData(uint80)(uint80,int256,uint256,uint256,uint80)" "$id" \
    --rpc-url mainnet | sed -n '4p' | sed 's/ .*//'
done
```

Differencing consecutive `updatedAt` values gives the cadence. Run the same against
`STRC_USD.FEED` and the arbitrum `AAPL_USD.FEED` to see the contrast.

### What the other suite does, and why it moved

`test/mainnet/StrcSpcxOraclesFork.t.sol` (`StrcSpcxOraclesForkTest`) checks all four STRC and SPCX
aggregators against the live feeds. It was pinned at 25926463 while this was being investigated, so
its two SPCX tests —

- `test_fork_fxUSD_SPCX_matchesLiveFeeds`
- `test_fork_stETH_SPCX_matchesLiveFeeds`

— were failing for the reason described here rather than for anything about the aggregators. It is now
pinned at **25955214** (Fri 11 Sep 2026 15:59 UTC, mid-session, SPCX 42 minutes old), where all five
of its tests pass. The outage is no longer that suite's job; it is
`SpcxWeekendOutageForkTest`'s.

## What to do about it

### The decision, stated plainly

On a weekend the last SPCX price **is** the correct price: the market is shut and the value has not
moved. Reverting turns a legitimate reading into "unavailable", which is the error the oracle
robustness programme exists to remove. But the heartbeat is also the only thing that detects a genuine
feed outage, and widening it to cover a market closure means a real outage goes unnoticed for just as
long. There is no setting that gets both.

This is the same trade-off as `WstETHRateLib.DEFAULT_MIN_RATE`: a bound too tight turns a real reading
into "unavailable"; a bound too loose stops detecting failure.

### Recommended: size the bound to the longest scheduled closure, and say so

`HEARTBEAT` for a market-hours feed should be a **market-closure bound**, not a claim about the feed's
update interval, and the comment must say which it is. Otherwise the next reader sizes it as an update
interval again.

The longest *observed* closure is 89.6 h. The longest *possible* US equity closure is longer — a
Christmas or New Year falling to give Thursday close → Monday open, and the exchange's own
discretionary closures (weather, national days of mourning) have historically added days. A bound
derived from the exchange calendar rather than from one observation is the only defensible number.

**Before setting it, confirm what Chainlink publishes for `spcx-usd.data.eth`.** Two outcomes, and
they call for different things:

- **Chainlink documents 86400.** The feed is violating its own specification and that should be raised
  with them. Our bound still has to tolerate reality in the meantime.
- **Chainlink documents deviation-only, or a market-hours heartbeat.** Our configuration was simply
  wrong, and the fix is ours alone.

### Three things worth building, in the order they pay off

**1. A liveness test that samples many blocks, not one.** The defect is invisible to a single pinned
block chosen on a weekday, and invisible to a `latest` run made Monday-to-Friday. A test that walks a
window — say every 6 hours across 10 days — and asserts each aggregator answers, would have caught
this the day SPCX was added, and will catch the next feed with the same shape:

```
for ts in window(start, end, 6 hours):
    block = find_block(ts)
    fork at block
    assert aggregator.latestAnswer() does not revert
```

Foundry can do this with `vm.createSelectFork(url, blockNumber)` inside a loop, so it is one test
contract rather than a pinned suite per block. It is slow and RPC-heavy, so it belongs in a nightly
job rather than in `yarn test` — but it is the only shape that finds a gap that only exists at
weekends. Report the largest gap per feed rather than pass/fail alone, so a feed drifting toward its
bound is visible before it crosses.

**2. A market-calendar source, so the bound is derived rather than guessed.** Exchange holiday
calendars are published (NYSE and Nasdaq both publish theirs years ahead). Deriving
`max(scheduled closure) + margin` from that calendar, and regenerating the constant when the calendar
is updated, turns a magic number into a computed one. It also makes the *next* market-hours feed
automatic rather than another investigation. This is offchain work — the constant is baked in at
compile time — and fits the existing `offchain_feeds` tooling.

**3. A conformance check that a feed's configured heartbeat matches its observed behaviour.** For each
feed constant in `src/feeds/`, read the last N rounds and assert the largest gap is within the
configured `HEARTBEAT`. That is the check that makes the class of defect impossible to reintroduce,
rather than fixing this one instance. It needs the chain, so it is the same nightly job as (1).

### What this does not settle

Whether SPCX belongs as an oracle input at all. A position quoted against it cannot be liquidated
while the market is shut, and widening the heartbeat does not change that — it only stops the oracle
from announcing the fact. That is a risk decision rather than a code one, but this is the point at
which it surfaces.

## Changing it is a redeploy

`SPCX_USD` is an `internal` library, so its constants are inlined into every contract that imports it.
Changing `HEARTBEAT` changes the creation bytecode of both deployed SPCX aggregators. Their baselines
in `deployed.json` are recorded against the current source, so this is a redeploy and a new baseline,
not an edit.
