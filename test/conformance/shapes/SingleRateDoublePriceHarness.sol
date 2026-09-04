// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorHarness} from "@harbor-price-test/conformance/AggregatorHarness.sol";
import {OracleSource, SourceKind} from "@harbor-price-test/conformance/OracleSourceConformance.sol";
import {Aggregator_SingleRate_DoublePrice} from "@harbor-price/aggregators/base/Aggregator_SingleRate_DoublePrice.sol";

/// @title Conformance harness for aggregators shaped as one rate feed and a price from two feeds
/// @notice A concrete test names the three feeds its aggregator was wired to; this installs a mock at
///         each and applies the conformance tests. The getters it reads back are the shape's own, so
///         renaming one breaks this file rather than silently testing nothing.
abstract contract SingleRateDoublePriceHarness is AggregatorHarness {
    /// @notice The feed the aggregator reads its wrapped-to-underlying rate from.
    function _rateFeed() internal pure virtual returns (address);

    /// @notice The numerator of the two-feed price.
    function _firstFeed() internal pure virtual returns (address);

    /// @notice The denominator of the two-feed price.
    function _secondFeed() internal pure virtual returns (address);

    function _installSources() internal override {
        _installFeedOnce(_rateFeed(), RATE_FEED_DECIMALS, int256(RATE_FEED_ANSWER));
        _installFeedOnce(_firstFeed(), PRICE_FEED_DECIMALS, int256(PRICE_ANSWER));
        _installFeedOnce(_secondFeed(), PRICE_FEED_DECIMALS, int256(SECOND_PRICE_ANSWER));
    }

    /// @notice Everything the aggregator under test reads.
    function _sources() internal pure override returns (OracleSource[] memory sources) {
        sources = new OracleSource[](3);
        sources[0] = OracleSource({at: _rateFeed(), kind: SourceKind.ChainlinkFeed});
        sources[1] = OracleSource({at: _firstFeed(), kind: SourceKind.ChainlinkFeed});
        sources[2] = OracleSource({at: _secondFeed(), kind: SourceKind.ChainlinkFeed});
    }

    /// @notice The aggregator reads exactly the feeds the test declared, so the mocks it was driven
    ///         with are the sources it uses in production.
    function test_wiring_readsTheDeclaredFeeds() public view {
        Aggregator_SingleRate_DoublePrice shaped = Aggregator_SingleRate_DoublePrice(address(aggregator));

        assertEq(address(shaped.RATE_FEED()), _rateFeed(), "RATE_FEED");
        assertEq(address(shaped.FIRST_FEED()), _firstFeed(), "FIRST_FEED");
        assertEq(address(shaped.SECOND_FEED()), _secondFeed(), "SECOND_FEED");
    }
}
