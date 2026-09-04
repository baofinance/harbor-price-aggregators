// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WrappedPriceOracleConformance} from "@harbor-price-test/conformance/WrappedPriceOracleConformance.sol";
import {MockAggregatorV3} from "@harbor-price-test/mock/MockAggregatorV3.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";

/// @title Stands an aggregator up against mocked sources and applies the conformance tests to it
/// @notice For aggregators that bake their sources in as constants, so there is no constructor
///         argument a mock could be passed through. On a chain that is not a fork of the one they
///         were written for, those addresses hold no code, and a high-level Solidity call carries an
///         `extcodesize` check — so the aggregator cannot even be constructed until a mock is
///         installed at each address it reads.
/// @dev That is what makes the arrangement self-checking: a source the shape harness fails to install
///      leaves its address codeless, and construction reverts. A silently half-mocked aggregator —
///      which would let the zero and staleness tests pass without exercising anything — cannot occur.
///      A construction revert in `setUp` therefore means a source the aggregator reads was not
///      declared, so no mock was installed at it.
abstract contract AggregatorHarness is WrappedPriceOracleConformance {
    /// @dev Far enough from zero that a feed timestamp can be set in the past without underflowing.
    uint256 internal constant START_TIME = 100_000;

    /// @notice Chainlink USD feeds report 8 decimals; the mocks stand in at the same scale.
    uint8 internal constant PRICE_FEED_DECIMALS = 8;

    /// @notice A dedicated rate feed reports the wrapped-to-underlying ratio with 18 decimals.
    uint8 internal constant RATE_FEED_DECIMALS = 18;

    /// @dev Values the mocked feeds answer with. The rate ones sit inside the bounds the rate
    ///      libraries enforce — a dedicated rate feed at 1.05, and a ratio of 3600/3000 = 1.2 where
    ///      the rate is the quotient of two price feeds. The price ones are only required to be
    ///      positive, and differ from each other so a composed price is not a degenerate 1.
    uint256 internal constant RATE_FEED_ANSWER = 1.05e18;
    uint256 internal constant RATE_NUMERATOR_ANSWER = 3600e8;
    uint256 internal constant RATE_DENOMINATOR_ANSWER = 3000e8;
    uint256 internal constant PRICE_ANSWER = 3000e8;
    uint256 internal constant SECOND_PRICE_ANSWER = 50_000e8;

    function setUp() public virtual {
        vm.warp(START_TIME);

        _installSources();
        aggregator = IHarborPriceAggregatorV3(_createAggregator());
    }

    /// @notice Install a mock at every address this aggregator reads. Runs before construction.
    /// @dev The shape harness implements this from the addresses its concrete test declares.
    function _installSources() internal virtual;

    /// @notice Construct the aggregator under test.
    function _createAggregator() internal virtual returns (address);

    /// @notice Install a Chainlink feed mock at `feed`, unless that address already carries one.
    /// @dev One aggregator can read the same feed in two roles — Monad's wstETH/BTC oracle takes
    ///      WSTETH/USD as both its rate numerator and its first price feed. Installing once, with the
    ///      rate's value winning, keeps the two roles consistent: the rate libraries reject a ratio
    ///      outside their bounds, whereas a price is free to be anything positive.
    function _installFeedOnce(address feed, uint8 decimals_, int256 answer) internal {
        if (feed.code.length > 0) {
            return;
        }
        vm.etch(feed, address(new MockAggregatorV3(decimals_)).code);
        MockAggregatorV3(feed).setDecimals(decimals_);
        MockAggregatorV3(feed).setAnswer(answer, block.timestamp);
    }
}
