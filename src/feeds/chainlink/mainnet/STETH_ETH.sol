// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink stETH/ETH Feed - Ethereum Mainnet
/// @notice Feed address and heartbeat for stETH/ETH price feed
/// @dev Reference: https://data.chain.link/feeds/ethereum/mainnet/steth-eth
// solhint-disable-next-line contract-name-capwords
library STETH_ETH {
    /// @notice Chainlink stETH/ETH aggregator address on Ethereum mainnet
    address internal constant FEED = 0x86392dC19c0b719886221c78AB11eb8Cf5c52812;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on 0.5% deviation
    uint256 internal constant HEARTBEAT = 86400;
}
