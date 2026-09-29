// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {
    OracleSourceConformance,
    OracleSource,
    SourceKind
} from "@harbor-price-test/conformance/OracleSourceConformance.sol";
import {console} from "forge-std/Test.sol";
import {MockAggregatorV3} from "@harbor-price-test/mock/MockAggregatorV3.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";
import {Aggregator_syrupUSDG_USD} from "@harbor-price/aggregators/robinhood/Aggregator_syrupUSDG_USD.sol";
import {IPriceOracleErrors} from "@bao/interfaces/IPriceOracleErrors.sol";

/// @title syrupUSDG/USD formula: Chainlink syrupUSDG/USDG × USDG/USD, invert false.
contract Aggregator_syrupUSDG_USD_Test is OracleSourceConformance {
    MockAggregatorV3 mockRateFeed;
    MockAggregatorV3 mockPriceFeed;

    uint256 constant DEFAULT_HEARTBEAT = 86400;
    uint256 constant VALID_RATE = 1.012e18;

    function _sources() internal view override returns (OracleSource[] memory sources) {
        sources = new OracleSource[](2);
        sources[0] = OracleSource({at: address(mockRateFeed), kind: SourceKind.ChainlinkFeed});
        sources[1] = OracleSource({at: address(mockPriceFeed), kind: SourceKind.ChainlinkFeed});
    }

    function setUp() public {
        vm.warp(100_000);

        mockRateFeed = new MockAggregatorV3(18);
        mockPriceFeed = new MockAggregatorV3(8);

        mockRateFeed.setAnswer(int256(VALID_RATE), block.timestamp);
        mockPriceFeed.setAnswer(1e8, block.timestamp);

        aggregator = IHarborPriceAggregatorV3(
            address(
                new Aggregator_syrupUSDG_USD(address(mockRateFeed), address(mockPriceFeed), DEFAULT_HEARTBEAT, 1, false)
            )
        );
    }

    function test_constructor_revertsOnZeroRateFeed() public {
        vm.expectRevert();
        new Aggregator_syrupUSDG_USD(address(0), address(mockPriceFeed), DEFAULT_HEARTBEAT, 1, false);
    }

    function test_constructor_revertsOnZeroPriceFeed() public {
        vm.expectRevert();
        new Aggregator_syrupUSDG_USD(address(mockRateFeed), address(0), DEFAULT_HEARTBEAT, 1, false);
    }

    function test_constructor_revertsOnZeroDivisor() public {
        vm.expectRevert();
        new Aggregator_syrupUSDG_USD(address(mockRateFeed), address(mockPriceFeed), DEFAULT_HEARTBEAT, 0, false);
    }

    function test_baseName() public view {
        assertEq(aggregator.baseName(), "syrupUSDG");
    }

    function test_quoteName() public view {
        assertEq(aggregator.quoteName(), "USD");
    }

    function test_oracleName() public view {
        assertEq(aggregator.oracleName(), "syrupUSDG/USD");
    }

    function test_version() public view {
        assertEq(aggregator.version(), 3);
    }

    function test_rateProvider() public view {
        assertEq(aggregator.rateProvider(), address(mockRateFeed));
    }

    function test_latestAnswer_returnsValidTuple() public view {
        (uint256 p1, uint256 p2, uint256 r1, uint256 r2) = aggregator.latestAnswer();
        uint256 yieldUsd = p1 * r1 / 1e18;

        console.log("=== syrupUSDG/USD formula ===");
        console.log("USDG/USD price (18 decimals):", p1);
        console.log("syrupUSDG/USDG rate (18 decimals):", r1);
        console.log("Harbor Yield USD (price*rate/1e18):", yieldUsd);
        console.log("Harbor Yield USD whole:", yieldUsd / 1e18);
        console.log("Harbor Yield USD 18dp remainder:", yieldUsd % 1e18);
        console.log("");

        assertEq(p1, 1e18, "USDG/USD price is not pre-multiplied");
        assertEq(p1, p2, "price1 == price2");
        assertEq(r1, VALID_RATE, "rate1");
        assertEq(r1, r2, "rate1 == rate2");
        assertEq(yieldUsd, VALID_RATE, "composed USD");
    }

    function test_latestAnswer_staleFeed_reverts() public {
        uint256 staleTime = block.timestamp - DEFAULT_HEARTBEAT - 43;
        mockPriceFeed.setAnswer(1e8, staleTime);

        vm.expectRevert(
            abi.encodeWithSelector(
                IPriceOracleErrors.StaleFeedData.selector,
                address(mockPriceFeed),
                staleTime,
                block.timestamp,
                DEFAULT_HEARTBEAT
            )
        );
        aggregator.latestAnswer();
    }

    function test_latestAnswer_staleRate_reverts() public {
        uint256 staleTime = block.timestamp - DEFAULT_HEARTBEAT - 1;
        mockRateFeed.setAnswer(int256(VALID_RATE), staleTime);

        vm.expectRevert(
            abi.encodeWithSelector(IPriceOracleErrors.StaleRateSource.selector, address(mockRateFeed), staleTime)
        );
        aggregator.latestAnswer();
    }

    function test_latestAnswer_zeroFeedPrice_reverts() public {
        mockPriceFeed.setAnswer(0, block.timestamp);

        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.ZeroPrice.selector, address(mockPriceFeed), 0));
        aggregator.latestAnswer();
    }

    function test_latestAnswer_invalidRate_reverts() public {
        uint256 lowRate = 0.9e18 - 1;
        mockRateFeed.setAnswer(int256(lowRate), block.timestamp);

        vm.expectRevert(abi.encodeWithSelector(IPriceOracleErrors.InvalidRate.selector, lowRate));
        aggregator.latestAnswer();
    }
}
