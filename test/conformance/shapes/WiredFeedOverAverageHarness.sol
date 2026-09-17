// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredAggregatorHarness} from "@harbor-price-test/conformance/WiredAggregatorHarness.sol";
import {WiredBasketHarness} from "@harbor-price-test/conformance/shapes/WiredBasketHarness.sol";

/// @title An aggregator whose price is its first feed divided by the average of the rest
/// @notice The basket is valued as its average member, so the base comes out priced in units of one
///         average member. MAG7 is seven stocks averaged this way.
/// @dev The arithmetic of the average is pinned by `test/prices/MultiFeedDivPriceLib.t.sol`; what this pins
///      is that a deployed aggregator averages the feeds it declares, all of them, over their own count.
abstract contract WiredFeedOverAverageHarness is WiredBasketHarness {
    /// @inheritdoc WiredAggregatorHarness
    function _expectedPrice() internal view override returns (uint256) {
        // The members' mean at 18 decimals, truncated as integer division truncates, and the base over it
        // carried at 18 decimals. Dividing by the sum instead is smaller by the member count; dividing by the
        // largest or the first member lands elsewhere again, because every member differs.
        return _scaledByRate((_priceAnswer(0) * 1e18) / (_memberSum() / _memberCount()));
    }
}
