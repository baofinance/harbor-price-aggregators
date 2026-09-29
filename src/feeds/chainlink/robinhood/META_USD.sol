// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink META/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized META/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library META_USD {
    /// @notice Chainlink META/USD aggregator address on Robinhood
    address internal constant FEED = 0x7C38C00C30BEe9378381E7B6135d7283356D71b1;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
