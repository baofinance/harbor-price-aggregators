// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink TSM/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized TSM/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library TSM_USD {
    /// @notice Chainlink TSM/USD aggregator address on Robinhood
    address internal constant FEED = 0x874cF94aa8eC88Fd9560094dD065f2fB3E41Fc2F;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
