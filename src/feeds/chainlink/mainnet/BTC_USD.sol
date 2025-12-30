// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink BTC/USD Feed - Ethereum Mainnet
/// @notice Feed address and heartbeat for BTC/USD price feed
/// @dev Reference: https://data.chain.link/feeds/ethereum/mainnet/btc-usd
// solhint-disable-next-line contract-name-capwords
library BTC_USD {
    /// @notice Chainlink BTC/USD aggregator address on Ethereum mainnet
    address internal constant FEED = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c;

    /// @notice Heartbeat: 1 hour (3600 seconds)
    /// @dev Feed updates at least once per heartbeat or on 0.5% deviation
    uint256 internal constant HEARTBEAT = 3600;
}
