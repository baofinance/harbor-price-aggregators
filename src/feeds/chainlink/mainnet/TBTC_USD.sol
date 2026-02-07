// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink TBTC/USD Feed - Ethereum Mainnet
/// @notice Feed address and heartbeat for TBTC/USD price feed
/// @dev Reference: https://data.chain.link/feeds/ethereum/mainnet/tbtc-usd
// solhint-disable-next-line contract-name-capwords
library TBTC_USD {
    /// @notice Chainlink TBTC/USD aggregator address on Ethereum mainnet
    address internal constant FEED = 0x8350b7De6a6a2C1368E7D4Bd968190e13E354297;

    /// @notice Heartbeat: 1 day (86400 seconds)
    /// @dev Permissive to avoid StaleFeedData when feed updates are less frequent
    uint256 internal constant HEARTBEAT = 86400;
}
