// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredAggregatorHarness} from "@harbor-price-test/conformance/WiredAggregatorHarness.sol";
import {WiredSingleFeedHarness} from "@harbor-price-test/conformance/shapes/WiredSingleFeedHarness.sol";

/// @title An aggregator that prices a leveraged token in the quote its underlying is fed in
/// @notice The Minter reports what one leveraged token is worth in units of its underlying, and the
///         feed reports what the underlying is worth in the quote asset. The price is the two applied
///         in turn, so the leveraged token's value moves with both its own backing and the market its
///         underlying is priced in — which is `_rateScalesThePrice()`, fixed here because a leveraged
///         token oracle is never anything else.
/// @dev This is also the one shape whose rate source is allowed to answer zero: a leveraged token
///      wiped out by a capped market is worth nothing, and `OracleSourceConformance` requires that to
///      arrive as a zero answer rather than as a revert. The scaling is what carries that zero into
///      the price, which is why the two travel together.
abstract contract WiredLeveragedTokenHarness is WiredSingleFeedHarness {
    /// @inheritdoc WiredAggregatorHarness
    function _rateScalesThePrice() internal pure override returns (bool) {
        return true;
    }
}
