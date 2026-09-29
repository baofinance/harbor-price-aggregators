// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink SLV/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized SLV/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library SLV_USD {
    /// @notice Chainlink SLV/USD aggregator address on Robinhood
    address internal constant FEED = 0x209b73908e92Ae021826eD79609845451Ecba2ce;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
