// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink COIN/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized COIN/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library COIN_USD {
    /// @notice Chainlink COIN/USD aggregator address on Robinhood
    address internal constant FEED = 0xA3a468A452940B7D6b69991207B508c609a98Ef2;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
