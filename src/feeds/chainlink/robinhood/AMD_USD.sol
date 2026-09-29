// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink AMD/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized AMD/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library AMD_USD {
    /// @notice Chainlink AMD/USD aggregator address on Robinhood
    address internal constant FEED = 0x943A29E7ae51A4798823ca9eEd2ed533B2A22C72;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
