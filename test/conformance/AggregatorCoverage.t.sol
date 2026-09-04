// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

/// @notice Every aggregator has a test, so one added without one fails the build rather than sitting
///         unnoticed. Twenty had no test before this check existed, and nothing said so.
/// @dev Scope is the formula aggregators under `src/aggregators/<chain>/`. The abstract shapes in
///      `src/aggregators/base/` are not aggregators and are skipped by reading the declaration, so a
///      shape cannot be mistaken for an untested aggregator, nor an aggregator excused as a shape.
///      The convention it enforces is that the test for `Aggregator_X.sol` is named
///      `Aggregator_X.t.sol`, wherever under `test/` it lives.
contract AggregatorCoverageTest is Test {
    uint64 internal constant TEST_TREE_DEPTH = 3;

    function _aggregatorDirectories() internal pure returns (string[] memory directories) {
        directories = new string[](4);
        directories[0] = "src/aggregators/mainnet";
        directories[1] = "src/aggregators/arbitrum";
        directories[2] = "src/aggregators/megaeth";
        directories[3] = "src/aggregators/monad";
    }

    function test_everyAggregatorHasATest() public view {
        Vm.DirEntry[] memory testEntries = vm.readDir("test", TEST_TREE_DEPTH);
        string[] memory directories = _aggregatorDirectories();

        uint256 checked = 0;
        for (uint256 i = 0; i < directories.length; i++) {
            Vm.DirEntry[] memory sources = vm.readDir(directories[i]);
            for (uint256 j = 0; j < sources.length; j++) {
                string memory path = sources[j].path;
                if (!vm.contains(path, ".sol")) {
                    continue;
                }

                string memory contractName = _stem(path);
                string memory source = vm.readFile(path);
                // An abstract shape is a template for aggregators, not one itself.
                if (vm.contains(source, string.concat("abstract contract ", contractName))) {
                    continue;
                }

                string memory expected = string.concat(contractName, ".t.sol");
                assertTrue(
                    _holdsFileNamed(testEntries, expected),
                    string.concat("no test for ", contractName, ": expected a file named ", expected, " under test/")
                );
                checked++;
            }
        }

        assertGt(checked, 0, "no aggregators found: the directories this check reads have moved");
    }

    /// @notice The file name of `path`, with its extensions removed: "a/b/Aggregator_X.sol" is "Aggregator_X".
    function _stem(string memory path) internal pure returns (string memory) {
        string[] memory segments = vm.split(path, "/");
        string memory fileName = segments[segments.length - 1];

        return vm.split(fileName, ".")[0];
    }

    /// @notice Whether any entry in the tree is a file with this exact name.
    function _holdsFileNamed(Vm.DirEntry[] memory entries, string memory fileName) internal pure returns (bool) {
        bytes32 wanted = keccak256(bytes(fileName));
        for (uint256 i = 0; i < entries.length; i++) {
            if (entries[i].isDir) {
                continue;
            }
            string[] memory segments = vm.split(entries[i].path, "/");
            if (keccak256(bytes(segments[segments.length - 1])) == wanted) {
                return true;
            }
        }

        return false;
    }
}
