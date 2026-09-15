// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {AggregatorHarness} from "@harbor-price-test/conformance/AggregatorHarness.sol";
import {OracleSource, SourceKind} from "@harbor-price-test/conformance/OracleSourceConformance.sol";
import {MockSUSDe} from "@harbor-price-test/mock/MockSUSDe.sol";
import {MockWstETH} from "@harbor-price-test/mock/MockWstETH.sol";
import {MockMinter} from "@harbor-price-test/mock/MockMinter.sol";

/// @title Stands up an aggregator whose sources are wired in as constants, and tests what the wiring must satisfy
/// @notice A deployable aggregator adds no arithmetic to the formula it extends — it only names the
///         sources for one chain. So what a test of one has to establish is: the pair it announces,
///         the rate provider it points at, and that the sources it reads are exactly the ones the
///         test declared. This provides all three, so a concrete test is a declaration and nothing
///         more.
/// @dev The set of sources is pinned from both sides, without reading a single getter:
///      - **No undeclared source.** Sources are installed with `vm.etch` at the addresses the test
///        declares, and nowhere else. An address the aggregator reads but the test did not declare
///        holds no code on a non-forked chain, and every read is a high-level call carrying an
///        `extcodesize` check — so construction reverts (`AggregatorHarness` documents this).
///      - **No unread declaration.** `OracleSourceConformance` drives each declared source to zero
///        and to unreachable in turn, and requires the aggregator to fail naming it. A declared
///        source the aggregator never reads produces no failure, and the conformance test goes red.
///      Together those make the declared set equal the read set. What they do not pin is which
///      source fills which *role* — a first and second price feed swapped are both still read. That
///      is a property of the composed value rather than of the wiring, and belongs to the tests that
///      assert the price itself.
abstract contract WiredAggregatorHarness is AggregatorHarness {
    /// @notice The wrapped-to-underlying rate source, or the zero address where the rate is a
    ///         constant rather than something read.
    function _rateSource() internal pure virtual returns (OracleSource memory);

    /// @notice The price feeds, in the order the aggregator's constructor takes them.
    function _priceFeeds() internal pure virtual returns (address[] memory);

    /// @notice Where the rate is the ratio of two feeds, the one underneath; the zero address where
    ///         the rate comes from a single source.
    /// @dev Some chains carry no feed for a wrapper's accrual directly, only the wrapped and the
    ///      unwrapped asset each quoted against a common third. Dividing one by the other recovers
    ///      the accrual, so `_rateSource()` names the numerator and this names the denominator.
    function _rateDenominatorFeed() internal pure virtual returns (address) {
        return address(0);
    }

    /// @notice The asset being priced, as this oracle announces it.
    function _expectedBaseName() internal pure virtual returns (string memory);

    /// @notice The asset it is priced in, as this oracle announces it.
    function _expectedQuoteName() internal pure virtual returns (string memory);

    /// @notice The exact price this aggregator must report from the values its sources are driven to.
    /// @dev Supplied by a composition harness rather than written per aggregator: the price is a
    ///      function of the shape — one feed, two feeds divided, two feeds multiplied, a feed scaled
    ///      by a leveraged token price — and a concrete test names its shape by which harness it
    ///      extends. That is the aggregator's specification; a literal would be the same statement
    ///      with the reasoning removed.
    function _expectedPrice() internal view virtual returns (uint256);

    /// @notice Whether the rate multiplies the composed price as well as being reported alongside it.
    /// @dev An independent dimension rather than a shape: it applies to a price from one feed and to
    ///      one from two alike. It is set where the pair being priced is a *wrapper* whose quote is
    ///      the underlying's — the feeds price the underlying, and the rate carries that to the
    ///      wrapper. The rate then appears in the answer twice, meaning different things: reported
    ///      unchanged so a consumer can convert an amount, and applied to the price so the value is
    ///      the wrapper's rather than the underlying's.
    function _rateScalesThePrice() internal pure virtual returns (bool) {
        return false;
    }

    /// @dev Applies the rate to a composed price where the aggregator does. A composition harness
    ///      passes its result through this rather than deciding for itself, so the two dimensions
    ///      stay independent.
    function _scaledByRate(uint256 price) internal view returns (uint256) {
        return _rateScalesThePrice() ? (_expectedRate() * price) / 1e18 : price;
    }

    /// @notice The exact rate it must report.
    /// @dev Derived rather than declared: an aggregator that reads a rate reports what its source
    ///      says, and one whose rate is a constant reports parity. Neither is a per-aggregator
    ///      choice, so neither is written out per aggregator.
    function _expectedRate() internal view virtual returns (uint256) {
        if (_rateSource().at == address(0)) {
            return 1e18;
        }
        if (_rateDenominatorFeed() != address(0)) {
            return (_installedAnswer(_rateSource().at) * 1e18) / _installedAnswer(_rateDenominatorFeed());
        }
        return RATE_FEED_ANSWER;
    }

    /// @notice What the feed in price-feed slot `index` actually answered, scaled to the 18 decimals
    ///         every aggregator works in — the value a composition harness computes from.
    /// @dev Read back from the installed mock rather than restated as a constant, because one address
    ///      can serve two roles at once: monad's wstETH/USD oracle reads WSTETH/USD as both its rate
    ///      numerator and its price feed, and its sUSDe oracles read USDE/USD as both the rate
    ///      denominator and the first price feed. The installer gives the rate's value precedence in
    ///      that case, so a constant would be right for every aggregator except those, and silently
    ///      wrong for them.
    function _priceAnswer(uint256 index) internal view returns (uint256) {
        return _installedAnswer(_priceFeeds()[index]);
    }

    /// @dev What a Chainlink mock at `feed` answers, scaled to 18 decimals.
    function _installedAnswer(address feed) internal view returns (uint256) {
        // slither-disable-next-line unused-return
        (, int256 answer, , , ) = AggregatorV3Interface(feed).latestRoundData();
        uint8 feedDecimals = AggregatorV3Interface(feed).decimals();
        return uint256(answer) * 10 ** (18 - uint256(feedDecimals));
    }

    /// @dev Installed before construction, because an aggregator reads each feed's `decimals()` in
    ///      its constructor. The rate source goes in first: where one address serves as both the
    ///      rate source and a price feed, the rate's value has to win, since the rate libraries
    ///      bound what they accept and a price is free to be anything positive.
    function _installSources() internal override {
        OracleSource memory rate = _rateSource();
        if (rate.at != address(0)) {
            _installRateSource(rate);
        }

        address[] memory feeds = _priceFeeds();
        for (uint256 i = 0; i < feeds.length; i++) {
            _installFeedOnce(feeds[i], PRICE_FEED_DECIMALS, int256(_answerToInstallAt(i)));
        }
    }

    /// @notice Everything the aggregator under test reads: its rate source, the feed underneath it
    ///         where the rate is a ratio, then its price feeds.
    function _sources() internal pure override returns (OracleSource[] memory sources) {
        OracleSource memory rate = _rateSource();
        address denominator = _rateDenominatorFeed();
        address[] memory feeds = _priceFeeds();

        uint256 rateCount = rate.at == address(0) ? 0 : 1;
        if (denominator != address(0)) {
            rateCount += 1;
        }
        sources = new OracleSource[](rateCount + feeds.length);
        if (rate.at != address(0)) {
            sources[0] = rate;
        }
        if (denominator != address(0)) {
            sources[rateCount - 1] = OracleSource({at: denominator, kind: SourceKind.ChainlinkFeed});
        }
        for (uint256 i = 0; i < feeds.length; i++) {
            sources[rateCount + i] = OracleSource({at: feeds[i], kind: SourceKind.ChainlinkFeed});
        }
    }

    /// @dev The price feeds are installed at values far apart, so a composed price cannot come out a
    ///      degenerate 1, which would hide a division performed the wrong way round.
    function _answerToInstallAt(uint256 index) private pure returns (uint256) {
        return index == 0 ? PRICE_ANSWER : SECOND_PRICE_ANSWER;
    }

    /// @dev fxSAVE, sUSDe and USDMY are all read through `convertToAssets(uint256)` and are one
    ///      `SourceKind` for that reason, so one ERC-4626 mock stands in for all three. `vm.etch`
    ///      copies code and not storage, so the rate is set through the mock's setter afterwards
    ///      rather than by a constructor that never runs at this address.
    function _installRateSource(OracleSource memory rate) private {
        address denominator = _rateDenominatorFeed();
        if (denominator != address(0)) {
            // A ratio rate: both halves are ordinary price feeds, quoted against a common third
            // asset, so they carry a price feed's decimals rather than a rate feed's.
            _installFeedOnce(rate.at, PRICE_FEED_DECIMALS, int256(RATE_NUMERATOR_ANSWER));
            _installFeedOnce(denominator, PRICE_FEED_DECIMALS, int256(RATE_DENOMINATOR_ANSWER));
        } else if (rate.kind == SourceKind.ChainlinkFeed) {
            _installFeedOnce(rate.at, RATE_FEED_DECIMALS, int256(RATE_FEED_ANSWER));
        } else if (rate.kind == SourceKind.Erc4626Rate) {
            vm.etch(rate.at, address(new MockSUSDe()).code);
            MockSUSDe(rate.at).setAssetsPerShare(RATE_FEED_ANSWER);
        } else if (rate.kind == SourceKind.WstETHRate) {
            vm.etch(rate.at, address(new MockWstETH()).code);
            MockWstETH(rate.at).setStEthPerToken(RATE_FEED_ANSWER);
        } else {
            vm.etch(rate.at, address(new MockMinter()).code);
            MockMinter(rate.at).setLeveragedTokenPrice(RATE_FEED_ANSWER);
        }
    }

    // =========================================================================
    // Identity
    // =========================================================================

    /// @notice The oracle announces the pair it prices, and its combined name is those two parts.
    /// @dev A consumer reads `oracleName()` to label a market, so it has to agree with the parts it
    ///      is built from rather than being a separately maintained string.
    function test_identity_announcesThePairItPrices() public view {
        assertEq(aggregator.baseName(), _expectedBaseName(), "baseName");
        assertEq(aggregator.quoteName(), _expectedQuoteName(), "quoteName");
        assertEq(
            aggregator.oracleName(),
            string.concat(_expectedBaseName(), "/", _expectedQuoteName()),
            "oracleName is baseName/quoteName"
        );
    }

    /// @notice Every aggregator in this repo answers to the v3 contract.
    /// @dev The version is how a consumer holding an address decides which return shape to expect,
    ///      so it is part of the answer rather than documentation.
    function test_identity_isVersionThree() public view {
        assertEq(aggregator.version(), 3);
    }

    // =========================================================================
    // Composition
    // =========================================================================

    /// @notice The answer is the documented function of what its sources said.
    /// @dev This is the one test that pins which source fills which role. Everything else about the
    ///      wiring establishes only that a source is read; only the composed value distinguishes a
    ///      numerator from a denominator, or a rate applied from a rate ignored.
    ///
    ///      The band is a single point for every aggregator here: they read one value per source and
    ///      report it as both ends. A band that opened up would mean an aggregator had begun
    ///      reporting a spread, which is a change in what the answer means and not a refinement of
    ///      it, so it is asserted rather than left to the ordering check.
    function test_composition_answersTheDocumentedFunctionOfItsSources() public view {
        (uint256 minPrice, uint256 maxPrice, uint256 minRate, uint256 maxRate) = aggregator.latestAnswer();

        assertEq(minPrice, _expectedPrice(), "minUnderlyingPrice");
        assertEq(maxPrice, _expectedPrice(), "maxUnderlyingPrice");
        assertEq(minRate, _expectedRate(), "minWrappedRate");
        assertEq(maxRate, _expectedRate(), "maxWrappedRate");
    }

    /// @notice The rate provider it points at is the source its rate is actually read from, and is
    ///         the zero address when the rate is a constant.
    /// @dev A consumer uses this to reach the wrapper directly — to convert an amount rather than
    ///      value it. Pointing at anything but the source the rate came from would have it convert
    ///      against one wrapper while valuing against another.
    function test_wiring_rateProviderIsTheRateSource() public view {
        assertEq(aggregator.rateProvider(), _rateSource().at);
    }
}
