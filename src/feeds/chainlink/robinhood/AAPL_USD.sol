// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink AAPL/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized AAPL/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library AAPL_USD {
    /// @notice Chainlink AAPL/USD aggregator address on Robinhood
    address internal constant FEED = 0x6B22A786bAa607d76728168703a39Ea9C99f2cD0;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
