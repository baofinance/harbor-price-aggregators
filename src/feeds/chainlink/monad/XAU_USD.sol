// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink XAU/USD Feed - Monad
/// @notice Feed address and heartbeat for XAU (gold)/USD price feed
// solhint-disable-next-line contract-name-capwords
library XAU_USD {
    /// @notice Chainlink XAU/USD aggregator address on Monad
    address internal constant FEED = 0x61dD33A34E47a181EE02e42eE0546a3DA808f1B4;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    uint256 internal constant HEARTBEAT = 86400;
}
