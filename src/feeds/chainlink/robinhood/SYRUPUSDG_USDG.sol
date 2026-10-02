// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink syrupUSDG/USDG rate feed - Robinhood
/// @notice Exchange-rate aggregator: USDG per syrupUSDG share, 18 decimals.
/// @dev Crypto, not `us_equities_24/5`. On-chain `description()` is
///      "syrupUSDG / USDG Exchange Rate" (Chainlink's UI may label it USD).
// solhint-disable-next-line contract-name-capwords
library SYRUPUSDG_USDG {
    /// @notice Chainlink syrupUSDG/USDG aggregator address on Robinhood
    address internal constant FEED = 0xDd194C66aDcb422F188a04434e4824D70c151cF0;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
