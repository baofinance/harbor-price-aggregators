// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink CRWV/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized CRWV/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library CRWV_USD {
    /// @notice Chainlink CRWV/USD aggregator address on Robinhood
    address internal constant FEED = 0xe1b3aABCAFAd1c94708dc1367dcfF8Aa4407487C;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
