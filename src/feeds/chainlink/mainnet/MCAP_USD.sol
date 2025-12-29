// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink Total Market Cap/USD Feed - Ethereum Mainnet
/// @notice Feed address and heartbeat for Total Crypto Market Cap/USD price feed
/// @dev Reference: https://data.chain.link/feeds/ethereum/mainnet/total-marketcap-usd
// solhint-disable-next-line contract-name-capwords
library MCAP_USD {
    /// @notice Chainlink Total Market Cap/USD aggregator address on Ethereum mainnet
    address internal constant FEED = 0xEC8761a0A73c34329CA5B1D3Dc7eD07F30e836e2;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on 2% deviation
    uint256 internal constant HEARTBEAT = 86400;
}
