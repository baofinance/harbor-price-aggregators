// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink ORCL/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized ORCL/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library ORCL_USD {
    /// @notice Chainlink ORCL/USD aggregator address on Robinhood
    address internal constant FEED = 0x0e6a64a2B58A6693a531E6c555f3A5d042eEA844;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
