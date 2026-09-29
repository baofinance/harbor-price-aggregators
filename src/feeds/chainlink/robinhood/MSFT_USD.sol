// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink MSFT/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized MSFT/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library MSFT_USD {
    /// @notice Chainlink MSFT/USD aggregator address on Robinhood
    address internal constant FEED = 0x45C3C877C15E6BA2EBB19eA114Ea508d14C1Af2E;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
