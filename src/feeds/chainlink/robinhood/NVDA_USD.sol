// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink NVDA/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized NVDA/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library NVDA_USD {
    /// @notice Chainlink NVDA/USD aggregator address on Robinhood
    address internal constant FEED = 0x379EC4f7C378F34a1B47E4F3cbeBCbAC3E8E9F15;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
