// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorHarness} from "@harbor-price-test/conformance/AggregatorHarness.sol";
// solhint-disable-next-line max-line-length
import {Aggregator_DoubleFeed_TwoFeedRate} from "@harbor-price/aggregators/base/Aggregator_DoubleFeed_TwoFeedRate.sol";

/// @title Conformance harness for aggregators whose rate is the ratio of two feeds and whose price comes from two more
/// @notice A concrete test names the four feeds its aggregator was wired to; this installs a mock at
///         each and applies the conformance tests. Feeds repeat across roles here — Monad's sUSDe
///         oracles read USDE/USD as both the rate denominator and the first price feed — so the rate's
///         values are installed first and a price role inherits whatever is already there.
abstract contract DoubleFeedTwoFeedRateHarness is AggregatorHarness {
    /// @notice The numerator of the rate ratio.
    function _rateNumeratorFeed() internal pure virtual returns (address);

    /// @notice The denominator of the rate ratio.
    function _rateDenominatorFeed() internal pure virtual returns (address);

    /// @notice The numerator of the two-feed price.
    function _firstFeed() internal pure virtual returns (address);

    /// @notice The denominator of the two-feed price.
    function _secondFeed() internal pure virtual returns (address);

    function _installSources() internal override {
        _installFeedOnce(_rateNumeratorFeed(), PRICE_FEED_DECIMALS, int256(RATE_NUMERATOR_ANSWER));
        _installFeedOnce(_rateDenominatorFeed(), PRICE_FEED_DECIMALS, int256(RATE_DENOMINATOR_ANSWER));
        _installFeedOnce(_firstFeed(), PRICE_FEED_DECIMALS, int256(PRICE_ANSWER));
        _installFeedOnce(_secondFeed(), PRICE_FEED_DECIMALS, int256(SECOND_PRICE_ANSWER));
    }

    /// @notice The aggregator reads exactly the feeds the test declared, so the mocks it was driven
    ///         with are the sources it uses in production.
    function test_wiring_readsTheDeclaredFeeds() public view {
        Aggregator_DoubleFeed_TwoFeedRate shaped = Aggregator_DoubleFeed_TwoFeedRate(address(aggregator));

        assertEq(address(shaped.RATE_NUMERATOR_FEED()), _rateNumeratorFeed(), "RATE_NUMERATOR_FEED");
        assertEq(address(shaped.RATE_DENOMINATOR_FEED()), _rateDenominatorFeed(), "RATE_DENOMINATOR_FEED");
        assertEq(address(shaped.FIRST_FEED()), _firstFeed(), "FIRST_FEED");
        assertEq(address(shaped.SECOND_FEED()), _secondFeed(), "SECOND_FEED");
    }
}
