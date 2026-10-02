// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink INTC/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized INTC/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library INTC_USD {
    /// @notice Chainlink INTC/USD aggregator address on Robinhood
    address internal constant FEED = 0x3f390C5C24628Ac7C489515402235FeAD71D1913;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
