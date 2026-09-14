// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorHarness} from "@harbor-price-test/conformance/AggregatorHarness.sol";
import {OracleSource, SourceKind} from "@harbor-price-test/conformance/OracleSourceConformance.sol";
// solhint-disable-next-line max-line-length
import {Aggregator_DirectPrice_TwoFeedRate} from "@harbor-price/aggregators/Aggregator_DirectPrice_TwoFeedRate.sol";

/// @title Conformance harness for aggregators whose rate is the ratio of two feeds and whose price is one feed
/// @notice A concrete test names the three feeds its aggregator was wired to; this installs a mock at
///         each and applies the conformance tests. Where the same feed serves two roles — the rate's
///         numerator is often also the price feed — the rate's value is installed first and the price
///         inherits it, because the rate is the constrained one.
abstract contract DirectPriceTwoFeedRateHarness is AggregatorHarness {
    /// @notice The numerator of the rate ratio.
    function _rateNumeratorFeed() internal pure virtual returns (address);

    /// @notice The denominator of the rate ratio.
    function _rateDenominatorFeed() internal pure virtual returns (address);

    /// @notice The feed the aggregator reads its price from.
    function _priceFeed() internal pure virtual returns (address);

    function _installSources() internal override {
        _installFeedOnce(_rateNumeratorFeed(), PRICE_FEED_DECIMALS, int256(RATE_NUMERATOR_ANSWER));
        _installFeedOnce(_rateDenominatorFeed(), PRICE_FEED_DECIMALS, int256(RATE_DENOMINATOR_ANSWER));
        _installFeedOnce(_priceFeed(), PRICE_FEED_DECIMALS, int256(PRICE_ANSWER));
    }

    /// @notice Everything the aggregator under test reads.
    function _sources() internal pure override returns (OracleSource[] memory sources) {
        sources = new OracleSource[](3);
        sources[0] = OracleSource({at: _rateNumeratorFeed(), kind: SourceKind.ChainlinkFeed});
        sources[1] = OracleSource({at: _rateDenominatorFeed(), kind: SourceKind.ChainlinkFeed});
        sources[2] = OracleSource({at: _priceFeed(), kind: SourceKind.ChainlinkFeed});
    }

    /// @notice The aggregator reads exactly the feeds the test declared, so the mocks it was driven
    ///         with are the sources it uses in production.
    function test_wiring_readsTheDeclaredFeeds() public view {
        Aggregator_DirectPrice_TwoFeedRate shaped = Aggregator_DirectPrice_TwoFeedRate(address(aggregator));

        assertEq(address(shaped.RATE_NUMERATOR_FEED()), _rateNumeratorFeed(), "RATE_NUMERATOR_FEED");
        assertEq(address(shaped.RATE_DENOMINATOR_FEED()), _rateDenominatorFeed(), "RATE_DENOMINATOR_FEED");
        assertEq(address(shaped.PRICE_FEED()), _priceFeed(), "PRICE_FEED");
    }
}
