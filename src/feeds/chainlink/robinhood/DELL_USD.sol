// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink DELL/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized DELL/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library DELL_USD {
    /// @notice Chainlink DELL/USD aggregator address on Robinhood
    address internal constant FEED = 0x1C6c8cADBe02E19129c39dDB92281cE4c0bf206b;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
