// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink wstETH/USD Feed - Monad
/// @notice Feed address and heartbeat for wstETH/USD price feed
// solhint-disable-next-line contract-name-capwords
library WSTETH_USD {
    /// @notice Chainlink wstETH/USD aggregator address on Monad
    address internal constant FEED = 0xe6cd21b31948503dB54A07875999979722504B9A;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    uint256 internal constant HEARTBEAT = 86400;
}
