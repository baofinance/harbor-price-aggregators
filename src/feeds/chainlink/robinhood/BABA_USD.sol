// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink BABA/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized BABA/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library BABA_USD {
    /// @notice Chainlink BABA/USD aggregator address on Robinhood
    address internal constant FEED = 0x62Cc8F9b5f56a33c9C8A60c8B92779f523c4E984;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
