// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink stETH/USD Feed - Ethereum Mainnet
/// @notice Feed address and heartbeat for stETH/USD price feed
/// @dev Reference: https://data.chain.link/feeds/ethereum/mainnet/steth-usd
// solhint-disable-next-line contract-name-capwords
library STETH_USD {
    /// @notice Chainlink stETH/USD aggregator address on Ethereum mainnet
    address internal constant FEED = 0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on 1% deviation
    uint256 internal constant HEARTBEAT = 86400;
}
