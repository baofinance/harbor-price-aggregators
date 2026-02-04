// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink USDe/USD Feed - Ethereum Mainnet
/// @notice Feed address and heartbeat for USDe/USD price feed
/// @dev Reference: https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&search=usde
// solhint-disable-next-line contract-name-capwords
library USDE_USD {
    /// @notice Chainlink USDe/USD aggregator address on Ethereum mainnet
    address internal constant FEED = 0xa569d910839Ae8865Da8F8e70FfFb0cBA869F961;

    /// @notice Heartbeat: 1 hour (3600 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation threshold
    uint256 internal constant HEARTBEAT = 3600;
}
