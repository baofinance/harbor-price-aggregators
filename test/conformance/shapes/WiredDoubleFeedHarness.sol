// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredAggregatorHarness} from "@harbor-price-test/conformance/WiredAggregatorHarness.sol";

/// @title An aggregator whose price is one feed divided by another
/// @notice Neither feed quotes the pair on its own; both quote their asset against a common third —
///         usually USD — so dividing the first by the second cancels it and leaves the pair. This is
///         the shape that can be wired backwards without anything else noticing, which is why the two
///         feeds are driven to values far apart: the quotient and its reciprocal are nowhere near
///         each other.
/// @dev The arithmetic is pinned by `test/prices/DoubleFeedPriceLib.t.sol`. Inversion is not offered
///      here because no wired aggregator uses it; one that did would state the reciprocal shape
///      rather than inherit a branch nothing exercises.
abstract contract WiredDoubleFeedHarness is WiredAggregatorHarness {
    /// @notice How many units of the quote asset one unit of the quotient is counted as. One unless
    ///         the pair is quoted in bulk — a whole market capitalisation rather than a single share.
    function _priceDivisor() internal pure virtual returns (uint256) {
        return 1;
    }

    /// @inheritdoc WiredAggregatorHarness
    function _expectedPrice() internal pure override returns (uint256) {
        // The first feed's answer over the second's, carried at 18 decimals, counted in the quote
        // asset's units. Taking the feeds the other way round gives the reciprocal, which is larger
        // by the square of their ratio and cannot be mistaken for this.
        return (FIRST_PRICE * _priceDivisor() * 1e18) / SECOND_PRICE;
    }
}
