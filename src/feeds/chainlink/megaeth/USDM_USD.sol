// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink USDM/USD Feed - MegaETH
/// @notice Feed address and heartbeat for USDM/USD price feed
// solhint-disable-next-line contract-name-capwords
library USDM_USD {
    /// @notice Chainlink USDM/USD aggregator address on MegaETH
    address internal constant FEED = 0xdFe0063491d9DeD8F8abCdd7AE04238A1e70D270;

    /// @notice Heartbeat: 1 day (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation threshold
    uint256 internal constant HEARTBEAT = 86400;
}
