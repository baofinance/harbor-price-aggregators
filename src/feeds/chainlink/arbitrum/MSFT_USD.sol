// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink MSFT/USD Feed - Arbitrum
/// @notice Feed address and heartbeat for MSFT/USD price feed
// solhint-disable-next-line contract-name-capwords
library MSFT_USD {
    /// @notice Chainlink MSFT/USD aggregator address on Arbitrum
    address internal constant FEED = 0xDde33fb9F21739602806580bdd73BAd831DcA867;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
