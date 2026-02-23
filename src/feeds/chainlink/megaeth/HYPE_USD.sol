// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink HYPE/USD Feed - MegaETH
/// @notice Feed address and heartbeat for HYPE/USD price feed
// solhint-disable-next-line contract-name-capwords
library HYPE_USD {
    /// @notice Chainlink HYPE/USD aggregator address on MegaETH (18 decimals)
    address internal constant FEED = 0x642C7127cDC688816e91CB9664322401B909d77c;

    /// @notice Heartbeat: 1 day (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation threshold
    uint256 internal constant HEARTBEAT = 86400;
}
