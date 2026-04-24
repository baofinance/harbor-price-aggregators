// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink MON/USD Feed - Monad
/// @notice Feed address and heartbeat for MON/USD price feed
// solhint-disable-next-line contract-name-capwords
library MON_USD {
    /// @notice Chainlink MON/USD aggregator address on Monad
    address internal constant FEED = 0xBcD78f76005B7515837af6b50c7C52BCf73822fb;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    uint256 internal constant HEARTBEAT = 86400;
}
