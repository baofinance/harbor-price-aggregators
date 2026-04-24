// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink BTC/USD Feed - Monad
/// @notice Feed address and heartbeat for BTC/USD price feed
// solhint-disable-next-line contract-name-capwords
library BTC_USD {
    /// @notice Chainlink BTC/USD aggregator address on Monad
    address internal constant FEED = 0xc1d4C3331635184fA4C3c22fb92211B2Ac9E0546;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    uint256 internal constant HEARTBEAT = 86400;
}
