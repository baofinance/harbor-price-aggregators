// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink USDE/USD Feed - Monad
/// @notice Feed address and heartbeat for USDE/USD price feed
// solhint-disable-next-line contract-name-capwords
library USDE_USD {
    /// @notice Chainlink USDE/USD aggregator address on Monad
    address internal constant FEED = 0x6b5902EABcE27C23FC97ea136504395b4d22C1FD;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    uint256 internal constant HEARTBEAT = 86400;
}
