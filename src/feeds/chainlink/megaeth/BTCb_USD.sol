// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink BTC.b/USD Feed - MegaETH
/// @notice Feed address and heartbeat for BTC.b (wrapped BTC) / USD price feed
// solhint-disable-next-line contract-name-capwords
library BTCb_USD {
    /// @notice Chainlink BTC.b/USD aggregator address on MegaETH (8 decimals)
    address internal constant FEED = 0xbCd3Fd9FdA21Cd595205aaF10047831373E28D4f;

    /// @notice Heartbeat: 1 day (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation threshold
    uint256 internal constant HEARTBEAT = 86400;
}
