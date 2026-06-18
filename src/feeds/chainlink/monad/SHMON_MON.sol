// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink shMON/MON Feed - Monad
/// @notice Feed address and heartbeat for shMON/MON rate feed (direct)
// solhint-disable-next-line contract-name-capwords
library SHMON_MON {
    /// @notice Chainlink shMON/MON aggregator address on Monad
    address internal constant FEED = 0x54a1020D118B9BeF3F3A4ec8E24AeEc9DFdBe4c3;

    /// @notice Heartbeat: 24 hours (86400 seconds)
    uint256 internal constant HEARTBEAT = 86400;
}
