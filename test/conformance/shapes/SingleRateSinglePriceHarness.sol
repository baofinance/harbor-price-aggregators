// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorHarness} from "@harbor-price-test/conformance/AggregatorHarness.sol";
import {Aggregator_SingleRate_SinglePrice} from "@harbor-price/aggregators/base/Aggregator_SingleRate_SinglePrice.sol";

/// @title Conformance harness for aggregators shaped as one rate feed and one price feed
/// @notice A concrete test names the two feeds its aggregator was wired to; this installs a mock at
///         each and applies the conformance tests. The getters it reads back are the shape's own, so
///         renaming one breaks this file rather than silently testing nothing.
abstract contract SingleRateSinglePriceHarness is AggregatorHarness {
    /// @notice The feed the aggregator reads its wrapped-to-underlying rate from.
    function _rateFeed() internal pure virtual returns (address);

    /// @notice The feed the aggregator reads its price from.
    function _priceFeed() internal pure virtual returns (address);

    function _installSources() internal override {
        _installFeedOnce(_rateFeed(), RATE_FEED_DECIMALS, int256(RATE_FEED_ANSWER));
        _installFeedOnce(_priceFeed(), PRICE_FEED_DECIMALS, int256(PRICE_ANSWER));
    }

    /// @notice The aggregator reads exactly the feeds the test declared, so the mocks it was driven
    ///         with are the sources it uses in production.
    function test_wiring_readsTheDeclaredFeeds() public view {
        Aggregator_SingleRate_SinglePrice shaped = Aggregator_SingleRate_SinglePrice(address(aggregator));

        assertEq(address(shaped.RATE_FEED()), _rateFeed(), "RATE_FEED");
        assertEq(address(shaped.PRICE_FEED()), _priceFeed(), "PRICE_FEED");
    }
}
