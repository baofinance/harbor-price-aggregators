// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink XAG/USD Feed - Ethereum Mainnet
/// @notice Feed address and heartbeat for XAG/USD (silver) price feed
/// @dev Reference: https://data.chain.link/feeds/ethereum/mainnet/xag-usd
// solhint-disable-next-line contract-name-capwords
library XAG_USD {
    /// @notice Chainlink XAG/USD aggregator address on Ethereum mainnet
    address internal constant FEED = 0x379589227b15F1a12195D3f2d90bBc9F31f95235;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on 0.24% deviation
    uint256 internal constant HEARTBEAT = 86400;
}
