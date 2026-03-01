// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Chainlink wstETH/stETH Feed - MegaETH
/// @notice Feed address and heartbeat for wstETH/stETH rate feed
// solhint-disable-next-line contract-name-capwords
library WSTETH_STETH {
    /// @notice Chainlink wstETH/stETH aggregator address on MegaETH
    address internal constant FEED = 0xe020C0Abc50E6581A95cb79Ff1021728C9Ec0640;

    /// @notice Heartbeat: 1 day (86400 seconds)
    /// @dev Feed updates at least once per heartbeat or on deviation threshold
    uint256 internal constant HEARTBEAT = 86400;
}
