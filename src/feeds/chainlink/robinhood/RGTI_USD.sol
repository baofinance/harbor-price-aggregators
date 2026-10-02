// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink RGTI/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized RGTI/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library RGTI_USD {
    /// @notice Chainlink RGTI/USD aggregator address on Robinhood
    address internal constant FEED = 0x2A045cF1C49c61c166C036d2f06FA2D2d984f765;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
