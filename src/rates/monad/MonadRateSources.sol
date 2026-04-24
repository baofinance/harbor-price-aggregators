// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Monad rate sources (CL-only, no interfaces)
/// @notice wstETH/USD uses direct WSTETH_USD feed; sUSDe has direct SUSDE_USD (no aggregator needed for sUSDe/USD).
/// For wstETH/BTC, wstETH/XAU, sUSDe/BTC, sUSDe/ETH, sUSDe/XAU the rate (wstETH/stETH or sUSDe/USDe)
/// is derived via TwoFeedRatioRateLib when needed; price uses the direct wrapper feed.
/// shMON/USD has no direct feed: rate from SHMON_MON, price = rate * MON_USD (ChainlinkRateLib + single price).
/// Feed addresses and heartbeats live in @harbor-price/feeds/chainlink/monad/.
