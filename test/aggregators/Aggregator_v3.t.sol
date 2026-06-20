// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {MockAggregatorV3} from "@harbor-price-test/mock/MockAggregatorV3.sol";
import {MockFxSAVE} from "@harbor-price-test/mock/MockFxSAVE.sol";
import {MockWstETH} from "@harbor-price-test/mock/MockWstETH.sol";
import {Aggregator_fxUSD_BTC} from "@harbor-price/aggregators/mainnet/Aggregator_fxUSD_BTC.sol";
import {Aggregator_stETH_BTC} from "@harbor-price/aggregators/mainnet/Aggregator_stETH_BTC.sol";
import {FxSaveRateLib} from "@harbor-price/rates/FxSaveRateLib.sol";
import {WstETHRateLib} from "@harbor-price/rates/WstETHRateLib.sol";
import {ChainlinkFeedLib} from "@harbor-price/feeds/chainlink/ChainlinkFeedLib.sol";

/// @title v3 Aggregator Integration Tests
/// @notice Tests for v3 aggregator contracts with mocked dependencies
contract Aggregator_v3_Test is Test {
    MockFxSAVE mockFxSave;
    MockWstETH mockWstETH;
    MockAggregatorV3 mockPriceFeed;
    MockAggregatorV3 mockFirstFeed;
    MockAggregatorV3 mockSecondFeed;

    uint256 constant DEFAULT_HEARTBEAT = 3600;
    uint256 constant VALID_FXSAVE_RATE = 1.05e18;
    uint256 constant VALID_WSTETH_RATE = 1.15e18;

    function setUp() public {
        // Warp to a reasonable timestamp to avoid underflow in staleness tests
        vm.warp(100_000);

        mockFxSave = new MockFxSAVE();
        mockWstETH = new MockWstETH();
        mockPriceFeed = new MockAggregatorV3(8);
        mockFirstFeed = new MockAggregatorV3(8);
        mockSecondFeed = new MockAggregatorV3(8);

        // Set valid default values
        mockFxSave.setAssetsPerShare(VALID_FXSAVE_RATE);
        mockWstETH.setStEthPerToken(VALID_WSTETH_RATE);
        mockPriceFeed.setAnswer(50000e8, block.timestamp); // BTC/USD = 50000
        mockFirstFeed.setAnswer(3000e8, block.timestamp); // ETH/USD = 3000
        mockSecondFeed.setAnswer(50000e8, block.timestamp); // BTC/USD = 50000
    }

    // =========================================================================
    // Single Feed Pattern: Aggregator_fxUSD_BTC
    // =========================================================================

    // -------------------------------------------------------------------------
    // Constructor Validation
    // -------------------------------------------------------------------------

    function test_SingleFeed_constructor_revertsOnZeroFxsave() public {
        vm.expectRevert(abi.encodeWithSelector(Aggregator_fxUSD_BTC.InvalidAddress.selector, address(0)));
        new Aggregator_fxUSD_BTC(address(0), address(mockPriceFeed), DEFAULT_HEARTBEAT, 1, true);
    }

    function test_SingleFeed_constructor_revertsOnZeroPriceFeed() public {
        vm.expectRevert(abi.encodeWithSelector(Aggregator_fxUSD_BTC.InvalidAddress.selector, address(0)));
        new Aggregator_fxUSD_BTC(address(mockFxSave), address(0), DEFAULT_HEARTBEAT, 1, true);
    }

    function test_SingleFeed_constructor_revertsOnZeroDivisor() public {
        vm.expectRevert(abi.encodeWithSelector(Aggregator_fxUSD_BTC.InvalidDivisor.selector, 0));
        new Aggregator_fxUSD_BTC(address(mockFxSave), address(mockPriceFeed), DEFAULT_HEARTBEAT, 0, true);
    }

    function test_SingleFeed_constructor_acceptsValidArgs() public {
        Aggregator_fxUSD_BTC agg = new Aggregator_fxUSD_BTC(
            address(mockFxSave),
            address(mockPriceFeed),
            DEFAULT_HEARTBEAT,
            1,
            true
        );
        assertEq(address(agg.FXSAVE()), address(mockFxSave));
    }

    // -------------------------------------------------------------------------
    // Immutable Configuration
    // -------------------------------------------------------------------------

    function test_SingleFeed_immutables() public {
        Aggregator_fxUSD_BTC agg = new Aggregator_fxUSD_BTC(
            address(mockFxSave),
            address(mockPriceFeed),
            DEFAULT_HEARTBEAT,
            2,
            true
        );

        assertEq(address(agg.FXSAVE()), address(mockFxSave), "FXSAVE");
        assertEq(address(agg.PRICE_FEED()), address(mockPriceFeed), "PRICE_FEED");
        assertEq(agg.PRICE_FEED_DECIMALS(), 8, "PRICE_FEED_DECIMALS");
        assertEq(agg.PRICE_FEED_HEARTBEAT(), DEFAULT_HEARTBEAT, "PRICE_FEED_HEARTBEAT");
        assertEq(agg.PRICE_DIVISOR(), 2, "PRICE_DIVISOR");
        assertTrue(agg.INVERT_PRICE(), "INVERT_PRICE");
    }

    // -------------------------------------------------------------------------
    // Interface Compliance
    // -------------------------------------------------------------------------

    function test_SingleFeed_interface() public {
        Aggregator_fxUSD_BTC agg = new Aggregator_fxUSD_BTC(
            address(mockFxSave),
            address(mockPriceFeed),
            DEFAULT_HEARTBEAT,
            1,
            true
        );

        assertEq(agg.baseName(), "fxUSD", "baseName");
        assertEq(agg.quoteName(), "BTC", "quoteName");
        assertEq(agg.oracleName(), "fxUSD/BTC", "oracleName");
        assertEq(agg.version(), 3, "version");
        assertEq(agg.rateProvider(), address(mockFxSave), "rateProvider");
    }

    // -------------------------------------------------------------------------
    // latestAnswer() - Single Feed
    // -------------------------------------------------------------------------

    function test_SingleFeed_latestAnswer_returnsCorrectTuple() public {
        Aggregator_fxUSD_BTC agg = new Aggregator_fxUSD_BTC(
            address(mockFxSave),
            address(mockPriceFeed),
            DEFAULT_HEARTBEAT,
            1,
            true // invert: 1/BTC_USD
        );

        // BTC/USD = 50000, inverted = 1/50000 = 0.00002 (in 18 decimals: 2e13)
        // Rate = 1.05e18
        (uint256 p1, uint256 p2, uint256 r1, uint256 r2) = agg.latestAnswer();

        // Price should be 1e36 / 50000e18 = 2e13
        assertEq(p1, 2e13, "price1");
        assertEq(p2, 2e13, "price2 should equal price1");
        assertEq(r1, VALID_FXSAVE_RATE, "rate1");
        assertEq(r2, VALID_FXSAVE_RATE, "rate2 should equal rate1");
    }

    function test_SingleFeed_latestAnswer_directPrice() public {
        Aggregator_fxUSD_BTC agg = new Aggregator_fxUSD_BTC(
            address(mockFxSave),
            address(mockPriceFeed),
            DEFAULT_HEARTBEAT,
            1,
            false // direct: passthrough
        );

        (uint256 p1, , , ) = agg.latestAnswer();
        // Price should be normalized: 50000e8 -> 50000e18
        assertEq(p1, 50000e18, "direct price should be normalized");
    }

    function test_SingleFeed_latestAnswer_staleFeed_reverts() public {
        Aggregator_fxUSD_BTC agg = new Aggregator_fxUSD_BTC(
            address(mockFxSave),
            address(mockPriceFeed),
            DEFAULT_HEARTBEAT,
            1,
            true
        );

        // Make feed stale
        uint256 staleTime = block.timestamp - DEFAULT_HEARTBEAT - 43;
        mockPriceFeed.setAnswer(50000e8, staleTime);

        vm.expectRevert(
            abi.encodeWithSelector(
                ChainlinkFeedLib.StaleFeedData.selector,
                address(mockPriceFeed),
                staleTime,
                block.timestamp,
                DEFAULT_HEARTBEAT
            )
        );
        agg.latestAnswer();
    }

    function test_SingleFeed_latestAnswer_invalidRate_reverts() public {
        Aggregator_fxUSD_BTC agg = new Aggregator_fxUSD_BTC(
            address(mockFxSave),
            address(mockPriceFeed),
            DEFAULT_HEARTBEAT,
            1,
            true
        );

        // Set rate below minimum (0.9e18)
        uint256 lowRate = 0.8e18;
        mockFxSave.setAssetsPerShare(lowRate);

        vm.expectRevert(abi.encodeWithSelector(FxSaveRateLib.InvalidRate.selector, lowRate));
        agg.latestAnswer();
    }

    // =========================================================================
    // Double Feed Pattern: Aggregator_stETH_BTC
    // =========================================================================

    // -------------------------------------------------------------------------
    // Constructor Validation
    // -------------------------------------------------------------------------

    function test_DoubleFeed_constructor_revertsOnZeroWsteth() public {
        vm.expectRevert(abi.encodeWithSelector(Aggregator_stETH_BTC.InvalidAddress.selector, address(0)));
        new Aggregator_stETH_BTC(
            address(0), // wsteth
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    function test_DoubleFeed_constructor_revertsOnZeroFirstFeed() public {
        vm.expectRevert(abi.encodeWithSelector(Aggregator_stETH_BTC.InvalidAddress.selector, address(0)));
        new Aggregator_stETH_BTC(
            address(mockWstETH),
            address(0),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    function test_DoubleFeed_constructor_revertsOnZeroSecondFeed() public {
        vm.expectRevert(abi.encodeWithSelector(Aggregator_stETH_BTC.InvalidAddress.selector, address(0)));
        new Aggregator_stETH_BTC(
            address(mockWstETH),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(0),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    function test_DoubleFeed_constructor_revertsOnZeroDivisor() public {
        vm.expectRevert(abi.encodeWithSelector(Aggregator_stETH_BTC.InvalidDivisor.selector, 0));
        new Aggregator_stETH_BTC(
            address(mockWstETH),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            0,
            false
        );
    }

    function test_DoubleFeed_constructor_acceptsValidArgs() public {
        Aggregator_stETH_BTC agg = new Aggregator_stETH_BTC(
            address(mockWstETH),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
        assertEq(address(agg.WSTETH()), address(mockWstETH));
    }

    // -------------------------------------------------------------------------
    // Immutable Configuration
    // -------------------------------------------------------------------------

    function test_DoubleFeed_immutables() public {
        Aggregator_stETH_BTC agg = new Aggregator_stETH_BTC(
            address(mockWstETH),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            7200,
            2,
            true
        );

        assertEq(address(agg.WSTETH()), address(mockWstETH), "WSTETH");
        assertEq(address(agg.FIRST_FEED()), address(mockFirstFeed), "FIRST_FEED");
        assertEq(agg.FIRST_FEED_DECIMALS(), 8, "FIRST_FEED_DECIMALS");
        assertEq(agg.FIRST_FEED_HEARTBEAT(), DEFAULT_HEARTBEAT, "FIRST_FEED_HEARTBEAT");
        assertEq(address(agg.SECOND_FEED()), address(mockSecondFeed), "SECOND_FEED");
        assertEq(agg.SECOND_FEED_DECIMALS(), 8, "SECOND_FEED_DECIMALS");
        assertEq(agg.SECOND_FEED_HEARTBEAT(), 7200, "SECOND_FEED_HEARTBEAT");
        assertEq(agg.PRICE_DIVISOR(), 2, "PRICE_DIVISOR");
        assertTrue(agg.INVERT_PRICE(), "INVERT_PRICE");
    }

    // -------------------------------------------------------------------------
    // Interface Compliance
    // -------------------------------------------------------------------------

    function test_DoubleFeed_interface() public {
        Aggregator_stETH_BTC agg = new Aggregator_stETH_BTC(
            address(mockWstETH),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            1,
            false
        );

        assertEq(agg.baseName(), "stETH", "baseName");
        assertEq(agg.quoteName(), "BTC", "quoteName");
        assertEq(agg.oracleName(), "stETH/BTC", "oracleName");
        assertEq(agg.version(), 3, "version");
        assertEq(agg.rateProvider(), address(mockWstETH), "rateProvider");
    }

    // -------------------------------------------------------------------------
    // latestAnswer() - Double Feed
    // -------------------------------------------------------------------------

    function test_DoubleFeed_latestAnswer_returnsCorrectTuple() public {
        Aggregator_stETH_BTC agg = new Aggregator_stETH_BTC(
            address(mockWstETH),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            1,
            false // direct: ETH/BTC = ETH/USD / BTC/USD
        );

        // ETH/USD = 3000, BTC/USD = 50000
        // ETH/BTC = 3000/50000 = 0.06 = 6e16
        // Rate = 1.15e18
        (uint256 p1, uint256 p2, uint256 r1, uint256 r2) = agg.latestAnswer();

        assertEq(p1, 6e16, "price1: 3000/50000 = 0.06");
        assertEq(p2, 6e16, "price2 should equal price1");
        assertEq(r1, VALID_WSTETH_RATE, "rate1");
        assertEq(r2, VALID_WSTETH_RATE, "rate2 should equal rate1");
    }

    function test_DoubleFeed_latestAnswer_invertedPrice() public {
        Aggregator_stETH_BTC agg = new Aggregator_stETH_BTC(
            address(mockWstETH),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            1,
            true // invert: BTC/ETH = BTC/USD / ETH/USD
        );

        // Inverted: BTC/ETH = 50000/3000 = 16.666...
        (uint256 p1, , , ) = agg.latestAnswer();

        // 50000e18 * 1e18 / 3000e18 = 16.666...e18
        assertApproxEqRel(p1, 16.666666666666666666e18, 1e14, "inverted price");
    }

    function test_DoubleFeed_latestAnswer_staleFirstFeed_reverts() public {
        Aggregator_stETH_BTC agg = new Aggregator_stETH_BTC(
            address(mockWstETH),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            1,
            false
        );

        // Make first feed stale
        uint256 staleTime = block.timestamp - DEFAULT_HEARTBEAT - 43;
        mockFirstFeed.setAnswer(3000e8, staleTime);

        vm.expectRevert(
            abi.encodeWithSelector(
                ChainlinkFeedLib.StaleFeedData.selector,
                address(mockFirstFeed),
                staleTime,
                block.timestamp,
                DEFAULT_HEARTBEAT
            )
        );
        agg.latestAnswer();
    }

    function test_DoubleFeed_latestAnswer_staleSecondFeed_reverts() public {
        Aggregator_stETH_BTC agg = new Aggregator_stETH_BTC(
            address(mockWstETH),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            1,
            false
        );

        // Make second feed stale
        uint256 staleTime = block.timestamp - DEFAULT_HEARTBEAT - 43;
        mockSecondFeed.setAnswer(50000e8, staleTime);

        vm.expectRevert(
            abi.encodeWithSelector(
                ChainlinkFeedLib.StaleFeedData.selector,
                address(mockSecondFeed),
                staleTime,
                block.timestamp,
                DEFAULT_HEARTBEAT
            )
        );
        agg.latestAnswer();
    }

    function test_DoubleFeed_latestAnswer_invalidRate_reverts() public {
        Aggregator_stETH_BTC agg = new Aggregator_stETH_BTC(
            address(mockWstETH),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            1,
            false
        );

        // Set rate below minimum (1e18)
        uint256 lowRate = 0.9e18;
        mockWstETH.setStEthPerToken(lowRate);

        vm.expectRevert(abi.encodeWithSelector(WstETHRateLib.InvalidRate.selector, lowRate));
        agg.latestAnswer();
    }

    function test_DoubleFeed_latestAnswer_rateAboveMax_reverts() public {
        Aggregator_stETH_BTC agg = new Aggregator_stETH_BTC(
            address(mockWstETH),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            1,
            false
        );

        // Set rate above maximum (2e18)
        uint256 highRate = 2.1e18;
        mockWstETH.setStEthPerToken(highRate);

        vm.expectRevert(abi.encodeWithSelector(WstETHRateLib.InvalidRate.selector, highRate));
        agg.latestAnswer();
    }
}
