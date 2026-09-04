// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console2} from "forge-std/Test.sol";

/// @title Base for the fork suites: selects the chain a suite needs, or fails saying what is missing
/// @notice A fork test is a test like any other. It does not skip itself when the environment is not
///         set up, because a suite that quietly does not run looks exactly like a suite that passes.
///         An unset RPC variable is a failing test, and the failure names the variable.
/// @dev Forking at the latest block is this repo's policy — its fork suites compare an aggregator
///      against the feeds as they stand. bao-base's `BaoTest.forkMainnet()` pins a shared block for
///      repos whose fork tests must be reproducible; the two policies must not be mixed inside one
///      suite, or which one is in force becomes unanswerable. The block reached is logged, so a
///      failure here can be re-run against the same state with `--fork-block-number`.
abstract contract ForkTest is Test {
    /// @notice Thrown when the environment holds no endpoint for the chain this suite needs.
    error RpcUrlNotSet(string environmentVariable);

    /// @notice Thrown when the endpoint that was reached is serving a different chain.
    error ForkIsOnTheWrongChain(string environmentVariable, uint256 expected, uint256 actual);

    /// @notice The environment variable holding the endpoint for this suite's chain.
    function _rpcEnvironmentVariable() internal pure virtual returns (string memory);

    /// @notice The id of the chain this suite's contracts are wired for.
    function _chainId() internal pure virtual returns (uint256);

    function setUp() public virtual {
        _selectFork();
    }

    /// @dev Virtual so a suite that one day needs a pinned block can replace the policy; nothing
    ///      overrides it today.
    function _selectFork() internal virtual {
        // Already on the right chain: a `--fork-url` / `--rpc-url` on the command line, or an anvil
        // forking it, put us here. Honour that rather than reaching for the environment, which is
        // what lets the same suite be pointed at another endpoint by hand.
        //
        // The chain is read through `vm.getChainId()` rather than `block.chainid`, because a chain id
        // cannot change within a transaction on a real chain and the compiler reads one accordingly —
        // so `block.chainid` after `createSelectFork` can still answer for the chain left behind.
        if (vm.getChainId() == _chainId()) {
            return;
        }

        string memory url = vm.envOr(_rpcEnvironmentVariable(), string(""));
        if (bytes(url).length == 0) {
            revert RpcUrlNotSet(_rpcEnvironmentVariable());
        }

        vm.createSelectFork(url);
        uint256 forkedChainId = vm.getChainId();
        if (forkedChainId != _chainId()) {
            revert ForkIsOnTheWrongChain(_rpcEnvironmentVariable(), _chainId(), forkedChainId);
        }

        console2.log(_rpcEnvironmentVariable(), "forked at block", block.number);
    }
}
