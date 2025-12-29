// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink XAU/USD Feed - Ethereum Mainnet
/// @notice Feed address and heartbeat for XAU/USD (gold) price feed
/// @dev Reference: https://data.chain.link/feeds/ethereum/mainnet/xau-usd
// solhint-disable-next-line contract-name-capwords
library XAU_USD {
    /// @notice Chainlink XAU/USD aggregator address on Ethereum mainnet
    address internal constant FEED = 0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on 0.24% deviation
    uint256 internal constant HEARTBEAT = 86400;
}
