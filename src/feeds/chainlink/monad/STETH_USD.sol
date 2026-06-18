// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink stETH/USD Feed - Monad
/// @notice Feed address and heartbeat for stETH/USD price feed
// solhint-disable-next-line contract-name-capwords
library STETH_USD {
    /// @notice Chainlink stETH/USD aggregator address on Monad
    address internal constant FEED = 0xad7AF5c6d78Ef5f4d3c4133593047d9E2A8BDa8d;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    uint256 internal constant HEARTBEAT = 86400;
}
