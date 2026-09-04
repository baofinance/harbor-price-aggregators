// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {ForkTest} from "@harbor-price-test/fork/ForkTest.sol";

/// @dev Names an environment variable that is never set, so the "missing endpoint" behaviour is the
///      same on every machine. `_selectFork` is exposed because these tests drive it directly rather
///      than through `setUp`, where a revert would fail the suite instead of being asserted.
contract UnsetEndpointForkTest is ForkTest {
    uint256 internal constant PROBE_CHAIN_ID = 42161;

    function _rpcEnvironmentVariable() internal pure override returns (string memory) {
        return "HARBOR_PRICE_AGGREGATORS_ENDPOINT_THAT_IS_NEVER_SET";
    }

    function _chainId() internal pure override returns (uint256) {
        return PROBE_CHAIN_ID;
    }

    function selectFork() external {
        _selectFork();
    }
}

/// @notice How the fork suites behave when the environment does or does not provide their endpoint.
contract ForkTestBehaviourTest is Test {
    UnsetEndpointForkTest internal probe;

    function setUp() public {
        probe = new UnsetEndpointForkTest();
    }

    /// @notice A missing endpoint fails the suite and names the variable to set, rather than skipping.
    function test_selectFork_failsWhenTheRpcUrlIsNotSet() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                ForkTest.RpcUrlNotSet.selector,
                "HARBOR_PRICE_AGGREGATORS_ENDPOINT_THAT_IS_NEVER_SET"
            )
        );
        probe.selectFork();
    }

    /// @notice An endpoint chosen on the command line is honoured: already on the chain, it forks
    ///         nothing and never consults the environment, which is what makes `--fork-url` work.
    function test_selectFork_honoursAnEndpointAlreadySelected() public {
        vm.chainId(42161);

        probe.selectFork();

        assertEq(block.chainid, 42161, "the pre-selected chain must be left alone");
    }
}
