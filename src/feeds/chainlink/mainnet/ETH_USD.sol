// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink ETH/USD Feed - Ethereum Mainnet
/// @notice Feed address and heartbeat for ETH/USD price feed
/// @dev Reference: https://data.chain.link/feeds/ethereum/mainnet/eth-usd
// solhint-disable-next-line contract-name-capwords
library ETH_USD {
    /// @notice Chainlink ETH/USD aggregator address on Ethereum mainnet
    address internal constant FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    /// @notice Heartbeat: 1 hour (3600 seconds)
    /// @dev Feed updates at least once per heartbeat or on 0.5% deviation
    uint256 internal constant HEARTBEAT = 3600;
}
