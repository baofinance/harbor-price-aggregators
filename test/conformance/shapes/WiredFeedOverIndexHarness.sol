// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredAggregatorHarness} from "@harbor-price-test/conformance/WiredAggregatorHarness.sol";
import {WiredBasketHarness} from "@harbor-price-test/conformance/shapes/WiredBasketHarness.sol";

/// @title An aggregator whose price is its first feed divided by an index of the rest
/// @notice The basket is valued as an index: the members' summed price divided by what that sum was on the
///         index's base date, so the index reads 1 on that date and moves with the basket afterwards. The base
///         comes out priced in units of the index. MAG7.i26 is seven stocks indexed to their prices on
///         1 January 2026.
/// @dev The arithmetic of the sum is pinned by `test/prices/MultiFeedSumPriceLib.t.sol`; what this pins is
///      that a deployed aggregator sums the feeds it declares, all of them, and indexes them against the base
///      date's sum it declares.
abstract contract WiredFeedOverIndexHarness is WiredBasketHarness {
    /// @notice The members' summed price on the index's base date, in the feeds' unit at 18 decimals.
    function _indexPrice() internal pure virtual returns (uint256);

    /// @inheritdoc WiredAggregatorHarness
    function _expectedPrice() internal view override returns (uint256) {
        // The index at 18 decimals - today's sum over the base date's - and the base over it, carried at 18
        // decimals. Both divisions truncate as the aggregator's do. An index taken the other way round, or the
        // average used in place of the sum, is off by orders of magnitude at the prices installed.
        uint256 index = (_memberSum() * 1e18) / _indexPrice();
        return _scaledByRate((_priceAnswer(0) * 1e18) / index);
    }
}
