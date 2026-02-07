// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink WBTC/BTC Feed - Ethereum Mainnet
/// @notice Feed address and heartbeat for WBTC/BTC price feed
/// @dev Reference: https://data.chain.link/feeds/ethereum/mainnet/wbtc-btc
// solhint-disable-next-line contract-name-capwords
library WBTC_BTC {
    /// @notice Chainlink WBTC/BTC aggregator address on Ethereum mainnet
    address internal constant FEED = 0xfdFD9C85aD200c506Cf9e21F1FD8dd01932FBB23;

    /// @notice Heartbeat: 1 day (86400 seconds)
    /// @dev Permissive to avoid StaleFeedData when feed updates are less frequent
    uint256 internal constant HEARTBEAT = 86400;
}
