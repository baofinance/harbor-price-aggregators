// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink STRC/USD Feed - Ethereum Mainnet
/// @notice Feed address and heartbeat for STRC/USD (Strategy Stretch Preferred) price feed
/// @dev ENS: strc-usd.data.eth
// solhint-disable-next-line contract-name-capwords
library STRC_USD {
    /// @notice Chainlink STRC/USD aggregator address on Ethereum mainnet
    address internal constant FEED = 0xf4d2076277fff631EFC4385Ab36b1f7734218d23;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Equity-style feed; updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
