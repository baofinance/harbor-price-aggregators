// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Arbitrum Oracle Constants
/// @notice Constants used by Arbitrum v3 oracles
library ArbitrumConstants {
    // MAG7 Index Price (sum of 7 stocks on 1-1-2026)
    // Set to current prices as of deployment - will be updated to 1-1-2026 prices when available
    // Current sum: 2635395000000000000000 (2635.395 in human readable)
    // Breakdown: AAPL: 273.345, MSFT: 487.58, TSLA: 475.075, GOOGL: 313.505, META: 662.945, AMZN: 232.535, NVDA: 190.41
    uint256 internal constant MAG7_I26_INDEX_PRICE = 2_635_395_000_000_000_000_000;
}
