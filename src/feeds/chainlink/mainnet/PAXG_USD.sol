// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink PAXG/USD Feed - Ethereum Mainnet
/// @notice Feed address and heartbeat for PAXG/USD price feed
/// @dev Reference: https://data.chain.link/feeds/ethereum/mainnet/paxg-usd
// solhint-disable-next-line contract-name-capwords
library PAXG_USD {
    /// @notice Chainlink PAXG/USD aggregator address on Ethereum mainnet
    address internal constant FEED = 0x9944D86CEB9160aF5C5feB251FD671923323f8C3;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on 0.5% deviation
    uint256 internal constant HEARTBEAT = 86400;
}
