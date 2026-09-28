// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {IWrappedPriceOracle} from "@bao/interfaces/IWrappedPriceOracle.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";

/// @title Conformance tests that every wrapped price oracle must satisfy
/// @notice These assert the contract consumers rely on, not the arithmetic of any one aggregator:
///         whatever an aggregator computes, its answer must be an ordered pair of prices and an
///         ordered pair of rates, expressed with 18 decimals, readable from a static context.
/// @dev Each aggregator shape base derives from this and assigns `aggregator` in its own `setUp`,
///      so every concrete aggregator test carries these tests without writing anything per aggregator.
abstract contract WrappedPriceOracleConformance is Test {
    /// @notice The oracle under test; each shape base's `setUp` assigns it.
    IHarborPriceAggregatorV3 aggregator;

    /// @dev Bounds for a wrapped rate expressed with 18 decimals — see `test_conformance_eighteenDecimals`.
    uint256 constant MIN_EIGHTEEN_DECIMAL_RATE = 1e15;
    uint256 constant MAX_EIGHTEEN_DECIMAL_RATE = 1e21;

    /// @notice The two prices are returned lowest first, so a consumer can value a position
    ///         conservatively by picking the end of the band that works against it.
    function test_conformance_priceBandOrdered() public view {
        (uint256 minPrice, uint256 maxPrice, , ) = aggregator.latestAnswer();

        assertLe(minPrice, maxPrice, "minUnderlyingPrice must not exceed maxUnderlyingPrice");
    }

    /// @notice The two rates are returned lowest first, for the same reason as the prices.
    function test_conformance_rateBandOrdered() public view {
        (, , uint256 minRate, uint256 maxRate) = aggregator.latestAnswer();

        assertLe(minRate, maxRate, "minWrappedRate must not exceed maxWrappedRate");
    }

    /// @notice A non-zero wrapped rate is expressed with 18 decimals, as the interface documents.
    /// @dev Every rate this repo produces is a wrapped-to-underlying accrual ratio, so it sits near
    ///      parity; the band admits three orders of magnitude either side of 1e18. A rate that
    ///      carried its source's native decimals instead — Chainlink feeds answer with 8 — would be
    ///      about 1e8, ten orders of magnitude below the band, so the band rejects that mistake.
    ///      Zero is admitted because zero has no scale: a zero rate is a value, not a decimals error.
    ///      The prices are deliberately not checked here. They legitimately span many orders of
    ///      magnitude across the quote assets, so no single band both admits every real price and
    ///      rejects a mis-scaled one; each aggregator's own test pins its price to an exact value.
    function test_conformance_eighteenDecimals() public view {
        (, , uint256 minRate, uint256 maxRate) = aggregator.latestAnswer();

        if (minRate != 0) {
            assertGe(minRate, MIN_EIGHTEEN_DECIMAL_RATE, "minWrappedRate is below 18-decimal scale");
            assertLe(minRate, MAX_EIGHTEEN_DECIMAL_RATE, "minWrappedRate is above 18-decimal scale");
        }
        if (maxRate != 0) {
            assertGe(maxRate, MIN_EIGHTEEN_DECIMAL_RATE, "maxWrappedRate is below 18-decimal scale");
            assertLe(maxRate, MAX_EIGHTEEN_DECIMAL_RATE, "maxWrappedRate is above 18-decimal scale");
        }
    }

    /// @notice Reading the oracle changes nothing: the whole call tree runs under STATICCALL.
    /// @dev Consumers read it from their own view functions and from off-chain `eth_call`s, so no
    ///      frame it reaches — the aggregator, its feeds, its rate provider — may write state.
    ///      Calling through the interface would compile to STATICCALL on its own; this issues the
    ///      raw call so the property is asserted against the deployed code rather than inherited
    ///      from the interface's `view` declaration, which a later edit could relax.
    function test_conformance_isView() public view {
        (bool success, bytes memory answer) = address(aggregator).staticcall(
            abi.encodeCall(IWrappedPriceOracle.latestAnswer, ())
        );
        assertTrue(success, "latestAnswer must succeed under STATICCALL");

        (uint256 minPrice, uint256 maxPrice, uint256 minRate, uint256 maxRate) = abi.decode(
            answer,
            (uint256, uint256, uint256, uint256)
        );
        (uint256 minPrice2, uint256 maxPrice2, uint256 minRate2, uint256 maxRate2) = aggregator.latestAnswer();

        assertEq(minPrice, minPrice2, "minUnderlyingPrice changed between reads");
        assertEq(maxPrice, maxPrice2, "maxUnderlyingPrice changed between reads");
        assertEq(minRate, minRate2, "minWrappedRate changed between reads");
        assertEq(maxRate, maxRate2, "maxWrappedRate changed between reads");
    }
}
