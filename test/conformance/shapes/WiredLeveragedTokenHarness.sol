// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredAggregatorHarness} from "@harbor-price-test/conformance/WiredAggregatorHarness.sol";

/// @title An aggregator that prices a leveraged token in the quote its underlying is fed in
/// @notice The Minter reports what one leveraged token is worth in units of its underlying, and the
///         feed reports what the underlying is worth in the quote asset. The price is the two
///         applied in turn, so the leveraged token's value moves with both its own backing and the
///         market its underlying is priced in.
/// @dev The Minter's number appears in the answer twice, and means different things in each place:
///         as the **rate**, it is reported unchanged, so a consumer can convert an amount of
///         leveraged tokens into underlying; as part of the **price**, it scales the feed. An
///         aggregator that reported the feed alone would leave the rate correct and the price wrong,
///         which is why the expected price is the scaled value rather than the feed's own.
///
///      This is also the one shape whose rate source is allowed to answer zero — a leveraged token
///      wiped out by a capped market is worth nothing, and `OracleSourceConformance` requires that
///      to arrive as a zero answer rather than a revert.
abstract contract WiredLeveragedTokenHarness is WiredAggregatorHarness {
    /// @inheritdoc WiredAggregatorHarness
    function _expectedPrice() internal pure override returns (uint256) {
        // The underlying's price in the quote asset, scaled by what one leveraged token is worth in
        // underlying. Both carry 18 decimals, so the product is brought back to 18.
        return (RATE_FEED_ANSWER * FIRST_PRICE) / 1e18;
    }
}
