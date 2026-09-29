// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink IONQ/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized IONQ/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library IONQ_USD {
    /// @notice Chainlink IONQ/USD aggregator address on Robinhood
    address internal constant FEED = 0x22EfeC4919baf55F360E0EDee4AbEB26DE4971eb;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
