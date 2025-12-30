// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink EUR/USD Feed - Ethereum Mainnet
/// @notice Feed address and heartbeat for EUR/USD price feed
/// @dev Reference: https://data.chain.link/feeds/ethereum/mainnet/eur-usd
// solhint-disable-next-line contract-name-capwords
library EUR_USD {
    /// @notice Chainlink EUR/USD aggregator address on Ethereum mainnet
    address internal constant FEED = 0xb49f677943BC038e9857d61E7d053CaA2C1734C1;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on 0.15% deviation
    uint256 internal constant HEARTBEAT = 86400;
}
