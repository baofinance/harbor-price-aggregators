// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink USO/USD Feed - Robinhood
/// @notice Feed address and heartbeat for Robinhood tokenized USO/USD
/// @dev Market hours: us_equities_24/5. Heartbeat 86400; weekend/holiday silence reverts stale.
// solhint-disable-next-line contract-name-capwords
library USO_USD {
    /// @notice Chainlink USO/USD aggregator address on Robinhood
    address internal constant FEED = 0x75a9c76Ef439e2C7c2E5a34Ab105EcFe3766431c;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
