// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink stETH/USD Feed - Base
/// @notice Feed address and heartbeat for stETH/USD price feed
// solhint-disable-next-line contract-name-capwords
library STETH_USD {
    /// @notice Chainlink stETH/USD aggregator address on Base
    address internal constant FEED = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation
    uint256 internal constant HEARTBEAT = 86400;
}
