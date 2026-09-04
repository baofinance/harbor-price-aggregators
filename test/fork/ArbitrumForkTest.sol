// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ForkTest} from "@harbor-price-test/fork/ForkTest.sol";

/// @notice Base for suites whose contracts are wired for Arbitrum One.
abstract contract ArbitrumForkTest is ForkTest {
    function _rpcEnvironmentVariable() internal pure override returns (string memory) {
        return "ARBITRUM_RPC_URL";
    }

    function _chainId() internal pure override returns (uint256) {
        return 42161;
    }
}
