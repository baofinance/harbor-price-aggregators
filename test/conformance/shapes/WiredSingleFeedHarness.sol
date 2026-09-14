// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredAggregatorHarness} from "@harbor-price-test/conformance/WiredAggregatorHarness.sol";

/// @title An aggregator whose price is its one price feed, optionally inverted and scaled
/// @notice The feed already quotes the pair, so the price is the feed's own answer — divided down
///         where the quote asset is counted in larger units than the feed reports, or turned upside
///         down where the feed quotes the pair the other way round and the aggregator has to report
///         the reciprocal.
/// @dev The arithmetic of the composition itself is pinned by `test/prices/SingleFeedPriceLib.t.sol`.
///      What this establishes is that a *wired* aggregator applies that composition to the feed it
///      was wired to, with the divisor and inversion it was wired with.
abstract contract WiredSingleFeedHarness is WiredAggregatorHarness {
    /// @notice How many units of the quote asset one feed unit is counted as. One unless the pair is
    ///         quoted in bulk — a whole market capitalisation rather than a single share.
    function _priceDivisor() internal pure virtual returns (uint256) {
        return 1;
    }

    /// @notice Whether the feed quotes the pair the other way round, so the reported price is its
    ///         reciprocal.
    function _priceIsInverted() internal pure virtual returns (bool) {
        return false;
    }

    /// @inheritdoc WiredAggregatorHarness
    function _expectedPrice() internal pure override returns (uint256) {
        if (_priceIsInverted()) {
            // One divided by the feed's answer, both carried at 18 decimals, then counted in the
            // quote asset's units.
            return (1e18 * _priceDivisor() * 1e18) / FIRST_PRICE;
        }
        return FIRST_PRICE / _priceDivisor();
    }
}
