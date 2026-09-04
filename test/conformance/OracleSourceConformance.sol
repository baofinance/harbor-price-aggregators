// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {WrappedPriceOracleConformance} from "@harbor-price-test/conformance/WrappedPriceOracleConformance.sol";
import {IFxSAVE} from "@harbor-price/interfaces/IFxSAVE.sol";
import {IWstETH} from "@bao/interfaces/IWstETH.sol";
import {IMinter} from "@harbor-price/interfaces/IMinter.sol";
import {IPriceOracleErrors} from "@bao/interfaces/IPriceOracleErrors.sol";
import {IWrappedPriceOracle} from "@bao/interfaces/IWrappedPriceOracle.sol";

/// @notice What an oracle reads from, and therefore how a test drives it and what its zero means.
/// @dev The kind carries the read function to override and the meaning of a zero, because both are
///      properties of the source rather than of the oracle that reads it.
enum SourceKind {
    /// @dev A Chainlink feed, read through `latestRoundData()`. Zero is a fault: a feed reporting no
    ///      price has failed, since an asset priced at nothing is not something a feed reports.
    ChainlinkFeed,
    /// @dev An ERC-4626-style wrapper (fxSAVE, sUSDe, USDM), read through `convertToAssets`. Zero is
    ///      a fault: a share redeeming for nothing is a broken vault, not a valuation.
    Erc4626Rate,
    /// @dev wstETH, read through `getStETHByWstETH`. Zero is a fault, for the same reason.
    WstETHRate,
    /// @dev A Harbor Minter, read through `leveragedTokenPrice()`. **Zero is data**: a leveraged
    ///      token is worth nothing once its market is fully capped, which is the designed behaviour
    ///      of a junior claim that has been wiped out, not a failure to price it.
    MinterLeveragedPrice
}

/// @notice One thing an oracle reads.
struct OracleSource {
    address at;
    SourceKind kind;
}

/// @title Conformance tests for what an oracle does when a source misbehaves
/// @notice Zero and unavailable are different facts. The value domain can hold zero; it cannot hold
///         "unknown". So unknown goes out of band as a revert, and zero stays in band as data. These
///         tests pin the line between them: a source driven to zero either produces a zero answer or
///         a revert, and which one it is depends on what a zero from that source means.
/// @dev Sources are perturbed with `vm.mockCall` against the real dependency's read function rather
///      than a mock's setter, so the perturbation is defined by the production ABI and would work
///      against a real source as well as a stand-in. Each case is taken from a snapshot and rolled
///      back, so the perturbations cannot accumulate.
abstract contract OracleSourceConformance is WrappedPriceOracleConformance {
    /// @dev Long enough to outlast any heartbeat in the repo and the tolerance `ChainlinkFeedLib`
    ///      adds to it. Staleness is produced by moving time forward rather than by backdating a
    ///      feed, so no heartbeat has to be known here, and a feed's `updatedAt` stays non-zero —
    ///      zero is the different fault of a feed that has never reported.
    uint256 internal constant STALE_AGE = 400 days;

    /// @notice Everything the oracle under test reads.
    function _sources() internal view virtual returns (OracleSource[] memory);

    /// @notice A source that answers zero is either priced at nothing or broken, and the two are told
    ///         apart by what it is: a wiped leveraged token is worth zero, a silent feed is a fault.
    function test_conformance_zeroSource() public {
        OracleSource[] memory sources = _sources();

        for (uint256 i = 0; i < sources.length; i++) {
            uint256 snapshot = vm.snapshotState();

            _answerZero(sources[i]);
            if (sources[i].kind == SourceKind.MinterLeveragedPrice) {
                (uint256 minPrice, uint256 maxPrice, uint256 minRate, uint256 maxRate) = aggregator.latestAnswer();
                assertEq(minRate, 0, "a wiped leveraged token must be reported as worth nothing");
                assertEq(maxRate, 0, "a wiped leveraged token must be reported as worth nothing");
                assertEq(minPrice, 0, "a zero rate carries the price to zero with it");
                assertEq(maxPrice, 0, "a zero rate carries the price to zero with it");
            } else {
                _assertFailsNaming(sources[i].at, "a source answers zero");
            }

            _restore(snapshot);
        }
    }

    /// @notice A feed that has stopped updating is unavailable, not a price: reading the last known
    ///         value would report a stale number as if it were current.
    function test_conformance_staleSourceReverts() public {
        OracleSource[] memory sources = _sources();

        for (uint256 i = 0; i < sources.length; i++) {
            if (sources[i].kind != SourceKind.ChainlinkFeed) {
                continue;
            }
            uint256 snapshot = vm.snapshotState();

            _letOnlyThisFeedGoStale(sources, i);
            _assertFailsNaming(sources[i].at, "a feed has stopped updating");

            _restore(snapshot);
        }
    }

    /// @notice A negative answer is not a price. It must not be carried into an unsigned value.
    function test_conformance_negativeSourceReverts() public {
        OracleSource[] memory sources = _sources();

        for (uint256 i = 0; i < sources.length; i++) {
            if (sources[i].kind != SourceKind.ChainlinkFeed) {
                continue;
            }
            uint256 snapshot = vm.snapshotState();

            _answerNegative(sources[i].at);
            _assertFailsNaming(sources[i].at, "a feed answers a negative price");

            _restore(snapshot);
        }
    }

    /// @notice A source that cannot be reached leaves the oracle with nothing to report, so it must
    ///         fail rather than substitute a value of its own.
    function test_conformance_unreachableSourceReverts() public {
        OracleSource[] memory sources = _sources();

        for (uint256 i = 0; i < sources.length; i++) {
            uint256 snapshot = vm.snapshotState();

            vm.mockCallRevert(sources[i].at, _readSelectorOf(sources[i].kind), "");
            (bool success, ) = address(aggregator).staticcall(abi.encodeCall(IWrappedPriceOracle.latestAnswer, ()));
            assertFalse(success, "an unreachable source must not be answered around");

            _restore(snapshot);
        }
    }

    /// @notice Undo a case: both the chain state and the mocks that drove it.
    /// @dev `vm.mockCall` registrations are not chain state, so a state snapshot does not undo them.
    ///      Clearing them alongside the revert is what stops one case leaking into the next — without
    ///      it, a feed left at zero makes the following case fail naming the wrong source.
    function _restore(uint256 snapshot) private {
        vm.clearMockedCalls();
        vm.revertToState(snapshot);
    }

    // =========================================================================
    // Driving a source
    // =========================================================================

    function _answerZero(OracleSource memory source) private {
        if (source.kind == SourceKind.ChainlinkFeed) {
            _answerChainlink(source.at, 0, block.timestamp);
        } else if (source.kind == SourceKind.Erc4626Rate) {
            vm.mockCall(source.at, abi.encodeWithSelector(IFxSAVE.convertToAssets.selector), abi.encode(uint256(0)));
        } else if (source.kind == SourceKind.WstETHRate) {
            vm.mockCall(source.at, abi.encodeWithSelector(IWstETH.getStETHByWstETH.selector), abi.encode(uint256(0)));
        } else {
            vm.mockCall(
                source.at,
                abi.encodeWithSelector(IMinter.leveragedTokenPrice.selector),
                abi.encode(uint256(0))
            );
        }
    }

    /// @notice Move far enough forward that every feed is stale, then bring all but one back.
    /// @dev Backdating the chosen feed instead would need its heartbeat, which differs per feed and
    ///      per role, and `ChainlinkFeedLib` allows a tolerance on top of it. Advancing time and
    ///      re-reporting the others at their own answers leaves exactly one feed stale, whatever its
    ///      heartbeat, and leaves every value unchanged.
    function _letOnlyThisFeedGoStale(OracleSource[] memory sources, uint256 stale) private {
        uint80[] memory rounds = new uint80[](sources.length);
        int256[] memory answers = new int256[](sources.length);
        for (uint256 i = 0; i < sources.length; i++) {
            if (sources[i].kind != SourceKind.ChainlinkFeed) {
                continue;
            }
            (rounds[i], answers[i], , , ) = AggregatorV3Interface(sources[i].at).latestRoundData();
        }

        vm.warp(block.timestamp + STALE_AGE);

        for (uint256 i = 0; i < sources.length; i++) {
            if (sources[i].kind != SourceKind.ChainlinkFeed || sources[i].at == sources[stale].at) {
                continue;
            }
            vm.mockCall(
                sources[i].at,
                abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
                abi.encode(rounds[i], answers[i], uint256(0), block.timestamp, rounds[i])
            );
        }
    }

    function _answerNegative(address feed) private {
        _answerChainlink(feed, -1, block.timestamp);
    }

    function _answerChainlink(address feed, int256 answer, uint256 updatedAt) private {
        vm.mockCall(
            feed,
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(uint80(1), answer, uint256(0), updatedAt, uint80(1))
        );
    }

    function _readSelectorOf(SourceKind kind) private pure returns (bytes memory) {
        if (kind == SourceKind.ChainlinkFeed) {
            return abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector);
        }
        if (kind == SourceKind.Erc4626Rate) {
            return abi.encodeWithSelector(IFxSAVE.convertToAssets.selector);
        }
        if (kind == SourceKind.WstETHRate) {
            return abi.encodeWithSelector(IWstETH.getStETHByWstETH.selector);
        }

        return abi.encodeWithSelector(IMinter.leveragedTokenPrice.selector);
    }

    // =========================================================================
    // Reading the failure
    // =========================================================================

    /// @notice The oracle failed, it failed with an error a consumer can decode, and where that error
    ///         carries an address it is the source that misbehaved.
    /// @dev Consumers match these failures by selector, so an undeclared error — or a panic from
    ///      arithmetic on a bad value — leaves them unable to tell a dead feed from a bug.
    function _assertFailsNaming(address source, string memory when) private view {
        (bool success, bytes memory failure) = address(aggregator).staticcall(
            abi.encodeCall(IWrappedPriceOracle.latestAnswer, ())
        );

        assertFalse(success, string.concat("expected a failure when ", when));
        assertGe(failure.length, 4, string.concat("failure carried no error when ", when));

        bytes4 selector = bytes4(failure);
        assertTrue(
            _isDeclaredFailure(selector),
            string.concat("failure is not one of the declared oracle errors when ", when)
        );
        if (_namesItsSource(selector)) {
            assertEq(
                _firstAddressArgument(failure),
                source,
                string.concat("failure names a different source when ", when)
            );
        }
    }

    function _isDeclaredFailure(bytes4 selector) private pure returns (bool) {
        return
            selector == IPriceOracleErrors.StaleFeedData.selector ||
            selector == IPriceOracleErrors.FeedNeverUpdated.selector ||
            selector == IPriceOracleErrors.NegativePrice.selector ||
            selector == IPriceOracleErrors.ZeroPrice.selector ||
            selector == IPriceOracleErrors.InvalidRate.selector ||
            selector == IPriceOracleErrors.StaleRateSource.selector;
    }

    function _namesItsSource(bytes4 selector) private pure returns (bool) {
        return
            selector == IPriceOracleErrors.StaleFeedData.selector ||
            selector == IPriceOracleErrors.FeedNeverUpdated.selector ||
            selector == IPriceOracleErrors.NegativePrice.selector ||
            selector == IPriceOracleErrors.ZeroPrice.selector ||
            selector == IPriceOracleErrors.StaleRateSource.selector;
    }

    function _firstAddressArgument(bytes memory failure) private pure returns (address argument) {
        // The first argument sits one word past the selector, which itself sits one word into the
        // bytes array, after its length.
        assembly {
            argument := mload(add(failure, 36))
        }
    }
}
