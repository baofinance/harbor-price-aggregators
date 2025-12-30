// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {HarborCustomFeedAndRateAggregator_v1} from "@harbor-price/price/HarborCustomFeedAndRateAggregator_v1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {MockWstETH} from "test/mock/MockWstETH.sol";
import {MockFxSAVE} from "test/mock/MockFxSAVE.sol";
import {MockAggregatorV3} from "test/mock/MockAggregatorV3.sol";

// V2 contract for upgrade testing - same as V1, used to verify upgrade works
contract HarborCustomFeedAndRateAggregator_v2 is HarborCustomFeedAndRateAggregator_v1 {
    constructor(
        address wsteth_,
        address fxsave_,
        address susdeUsdeFeed_,
        address wstethStethFeed_
    ) HarborCustomFeedAndRateAggregator_v1(wsteth_, fxsave_, susdeUsdeFeed_, wstethStethFeed_) {}
}

contract HarborCustomFeedAndRateAggregator_v1Test is Test {
    HarborCustomFeedAndRateAggregator_v1 oracle;
    MockWstETH mockWstEth;
    MockFxSAVE mockFxSave;
    MockAggregatorV3[] mockStockFeeds;
    MockAggregatorV3 mockUsdFeed;

    address owner = address(this);
    uint64 maxAge = 3600; // 1 hour
    uint256 maxDev = 5e16; // 5%

    // Test data
    uint256 wstEthRate = 1208351172000448378; // 1.208... stETH/wstETH
    uint256 aggregationDivisor = 6; // Divide by 6 to get average of 6 stocks

    // Stock prices in 8 decimals (normalized to 18 decimals in calculations)
    int256[6] stockPrices = [
        int256(15000000000), // AAPL: $150 (8 decimals)
        int256(14000000000), // GOOGLE: $140 (8 decimals)
        int256(50000000000), // NVDA: $500 (8 decimals)
        int256(18000000000), // AMZN: $180 (8 decimals)
        int256(40000000000), // MSFT: $400 (8 decimals)
        int256(35000000000) // META: $350 (8 decimals)
    ];

    int256 usdPrice = 283214000000; // 2832.14 USD/stETH with 8 decimals (stETH/USD feed - current market price)
    uint8 feedDecimals = 8;

    // ERC1967 implementation slot
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function setUp() public {
        // Deploy mocks
        mockWstEth = new MockWstETH();
        mockFxSave = new MockFxSAVE();
        mockUsdFeed = new MockAggregatorV3(feedDecimals);

        // Set mock values
        mockWstEth.setStEthPerToken(wstEthRate);
        mockUsdFeed.setAnswer(usdPrice, block.timestamp);

        // Deploy stock feed mocks
        for (uint256 i = 0; i < stockPrices.length; i++) {
            MockAggregatorV3 feed = new MockAggregatorV3(feedDecimals);
            feed.setAnswer(stockPrices[i], block.timestamp);
            mockStockFeeds.push(feed);
        }
    }

    function test_WstETH_Deployment() public {
        // Deploy wstETH oracle with custom feeds
        HarborCustomFeedAndRateAggregator_v1 implementation = new HarborCustomFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0) // WSTETH_STETH_FEED not used in tests
        );

        address[] memory customFeeds = new address[](mockStockFeeds.length);
        for (uint256 i = 0; i < mockStockFeeds.length; i++) {
            customFeeds[i] = address(mockStockFeeds[i]);
        }

        bytes memory initData = abi.encodeWithSelector(
            HarborCustomFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "WstETHToAggregatedStocks",
            HarborCustomFeedAndRateAggregator_v1.RateSource.WSTETH,
            customFeeds,
            address(mockUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedAndRateAggregator_v1(address(proxy));

        assertEq(oracle.owner(), owner, "Incorrect owner");
        assertTrue(bytes(oracle.oracleName()).length > 0, "Oracle name should not be empty");
        assertEq(oracle.getCustomFeedCount(), mockStockFeeds.length, "Incorrect custom feed count");
        assertEq(oracle.aggregationDivisor(), aggregationDivisor, "Incorrect aggregation divisor");
    }

    function test_GetPrice() public {
        HarborCustomFeedAndRateAggregator_v1 implementation = new HarborCustomFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        address[] memory customFeeds = new address[](mockStockFeeds.length);
        for (uint256 i = 0; i < mockStockFeeds.length; i++) {
            customFeeds[i] = address(mockStockFeeds[i]);
        }

        bytes memory initData = abi.encodeWithSelector(
            HarborCustomFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            HarborCustomFeedAndRateAggregator_v1.RateSource.WSTETH,
            customFeeds,
            address(mockUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedAndRateAggregator_v1(address(proxy));

        uint256 price = oracle.getPrice();
        (uint256 minPrice, uint256 maxPrice, uint256 minRate, ) = oracle.latestAnswer();

        console.log("=== wstETH Custom Feed Price ===");
        console.log("Price (wstETH in aggregated stocks/USD):", price);
        console.log("Min Price:", minPrice);
        console.log("Max Price:", maxPrice);
        console.log("wstETH Rate (wstETH/stETH):", minRate);

        // Calculate expected price manually
        // Sum all stock prices (normalized to 18 decimals)
        uint256 aggregatedPrice = 0;
        for (uint256 i = 0; i < stockPrices.length; i++) {
            // Normalize to 18 decimals: price * 1e10
            // casting to 'uint256' is safe because stockPrices are positive
            aggregatedPrice += uint256(stockPrices[i]) * 1e10;
        }

        // Divide by aggregation divisor
        uint256 normalizedAggregatedPrice = aggregatedPrice / aggregationDivisor;

        // Get USD feed price (normalized to 18 decimals)
        // casting to 'uint256' is safe because usdPrice is positive
        uint256 normalizedUsdPrice = uint256(usdPrice) * 1e10;

        console.log("");
        console.log("=== Stock Basket Units per 1 wstETH ===");
        console.log("Aggregated stock price (average of 6 stocks):", normalizedAggregatedPrice);
        console.log("stETH/USD feed price:", normalizedUsdPrice);
        // Calculate wstETH/USD price
        uint256 wstEthUsdPrice = Math.mulDiv(wstEthRate, normalizedUsdPrice, 1e18);
        console.log("wstETH/USD price:", wstEthUsdPrice);
        // The price represents units of aggregated basket per 1 wstETH
        console.log("Units of aggregated stock basket per 1 wstETH:", price);
        // Calculate expected: (wstETH_USD * 1e18) / aggregated_price
        uint256 expectedPrice = Math.mulDiv(wstEthUsdPrice, 1e18, normalizedAggregatedPrice);
        console.log("Expected units:", expectedPrice);

        assertTrue(price > 0, "Price should be positive");
        assertEq(price, expectedPrice, "Incorrect aggregated price");
    }

    function test_LatestAnswer() public {
        HarborCustomFeedAndRateAggregator_v1 implementation = new HarborCustomFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        address[] memory customFeeds = new address[](mockStockFeeds.length);
        for (uint256 i = 0; i < mockStockFeeds.length; i++) {
            customFeeds[i] = address(mockStockFeeds[i]);
        }

        bytes memory initData = abi.encodeWithSelector(
            HarborCustomFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            HarborCustomFeedAndRateAggregator_v1.RateSource.WSTETH,
            customFeeds,
            address(mockUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedAndRateAggregator_v1(address(proxy));

        (uint256 minPrice, uint256 maxPrice, uint256 minRate, uint256 maxRate) = oracle.latestAnswer();

        assertEq(minPrice, maxPrice, "Min/max price mismatch");
        assertEq(minRate, maxRate, "Min/max rate mismatch");
        assertEq(minRate, wstEthRate, "Incorrect rate");
        assertTrue(minPrice > 0, "Price should be positive");
    }

    function test_UpdateCustomFeedConstraints() public {
        HarborCustomFeedAndRateAggregator_v1 implementation = new HarborCustomFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        address[] memory customFeeds = new address[](mockStockFeeds.length);
        for (uint256 i = 0; i < mockStockFeeds.length; i++) {
            customFeeds[i] = address(mockStockFeeds[i]);
        }

        bytes memory initData = abi.encodeWithSelector(
            HarborCustomFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            HarborCustomFeedAndRateAggregator_v1.RateSource.WSTETH,
            customFeeds,
            address(mockUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedAndRateAggregator_v1(address(proxy));

        uint64 newMaxAge = 7200; // 2 hours
        uint256 newMaxDev = 10e16; // 10%

        vm.prank(owner);
        oracle.updateCustomFeedConstraints(newMaxAge, newMaxDev);

        // Check that all custom feeds have updated constraints
        for (uint256 i = 0; i < customFeeds.length; i++) {
            (uint64 maxAge_, uint256 maxDev_) = oracle.getConstraints(uint8(i + 1));
            assertEq(maxAge_, newMaxAge, "Incorrect maxAge for custom feed");
            assertEq(maxDev_, newMaxDev, "Incorrect maxDev for custom feed");
        }
    }

    function test_UpdateUsdFeedConstraints() public {
        HarborCustomFeedAndRateAggregator_v1 implementation = new HarborCustomFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        address[] memory customFeeds = new address[](mockStockFeeds.length);
        for (uint256 i = 0; i < mockStockFeeds.length; i++) {
            customFeeds[i] = address(mockStockFeeds[i]);
        }

        bytes memory initData = abi.encodeWithSelector(
            HarborCustomFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            HarborCustomFeedAndRateAggregator_v1.RateSource.WSTETH,
            customFeeds,
            address(mockUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedAndRateAggregator_v1(address(proxy));

        uint64 newMaxAge = 7200; // 2 hours
        uint256 newMaxDev = 10e16; // 10%

        vm.prank(owner);
        oracle.updateUsdFeedConstraints(newMaxAge, newMaxDev);

        (uint64 maxAge_, uint256 maxDev_) = oracle.getConstraints(100);
        assertEq(maxAge_, newMaxAge, "Incorrect maxAge for USD feed");
        assertEq(maxDev_, newMaxDev, "Incorrect maxDev for USD feed");
    }

    function test_GetCustomFeed() public {
        HarborCustomFeedAndRateAggregator_v1 implementation = new HarborCustomFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        address[] memory customFeeds = new address[](mockStockFeeds.length);
        for (uint256 i = 0; i < mockStockFeeds.length; i++) {
            customFeeds[i] = address(mockStockFeeds[i]);
        }

        bytes memory initData = abi.encodeWithSelector(
            HarborCustomFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            HarborCustomFeedAndRateAggregator_v1.RateSource.WSTETH,
            customFeeds,
            address(mockUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedAndRateAggregator_v1(address(proxy));

        for (uint256 i = 0; i < customFeeds.length; i++) {
            address feed = oracle.getCustomFeed(i);
            assertEq(feed, customFeeds[i], "Incorrect custom feed address");
        }
    }

    function test_Fuzz_WstETH_Rate(uint256 rateInput) public {
        // Bound wstETH rate to [1.0, 1.3] in 1e18
        uint256 rate = bound(rateInput, 1e18, 13e17);
        mockWstEth.setStEthPerToken(rate);

        HarborCustomFeedAndRateAggregator_v1 implementation = new HarborCustomFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        address[] memory customFeeds = new address[](mockStockFeeds.length);
        for (uint256 i = 0; i < mockStockFeeds.length; i++) {
            customFeeds[i] = address(mockStockFeeds[i]);
        }

        bytes memory initData = abi.encodeWithSelector(
            HarborCustomFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            HarborCustomFeedAndRateAggregator_v1.RateSource.WSTETH,
            customFeeds,
            address(mockUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedAndRateAggregator_v1(address(proxy));

        (, , uint256 minRate, uint256 maxRate) = oracle.latestAnswer();
        assertEq(minRate, rate, "Incorrect rate (fuzz)");
        assertEq(maxRate, rate, "Rate mismatch (fuzz)");
    }

    function test_Fuzz_AggregationDivisor(uint256 divisorInput) public {
        // Bound divisor to [1, 100]
        uint256 divisor = bound(divisorInput, 1, 100);

        HarborCustomFeedAndRateAggregator_v1 implementation = new HarborCustomFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        address[] memory customFeeds = new address[](mockStockFeeds.length);
        for (uint256 i = 0; i < mockStockFeeds.length; i++) {
            customFeeds[i] = address(mockStockFeeds[i]);
        }

        bytes memory initData = abi.encodeWithSelector(
            HarborCustomFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            HarborCustomFeedAndRateAggregator_v1.RateSource.WSTETH,
            customFeeds,
            address(mockUsdFeed),
            divisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedAndRateAggregator_v1(address(proxy));

        assertEq(oracle.aggregationDivisor(), divisor, "Incorrect aggregation divisor (fuzz)");

        uint256 price = oracle.getPrice();
        assertTrue(price > 0, "Price should be positive (fuzz)");
    }

    function test_GetRate() public {
        HarborCustomFeedAndRateAggregator_v1 implementation = new HarborCustomFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        address[] memory customFeeds = new address[](mockStockFeeds.length);
        for (uint256 i = 0; i < mockStockFeeds.length; i++) {
            customFeeds[i] = address(mockStockFeeds[i]);
        }

        bytes memory initData = abi.encodeWithSelector(
            HarborCustomFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            HarborCustomFeedAndRateAggregator_v1.RateSource.WSTETH,
            customFeeds,
            address(mockUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedAndRateAggregator_v1(address(proxy));

        uint256 rate = oracle.getRate();
        assertEq(rate, wstEthRate, "Incorrect rate from getRate()");
    }

    function test_Decimals() public {
        HarborCustomFeedAndRateAggregator_v1 implementation = new HarborCustomFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        address[] memory customFeeds = new address[](mockStockFeeds.length);
        for (uint256 i = 0; i < mockStockFeeds.length; i++) {
            customFeeds[i] = address(mockStockFeeds[i]);
        }

        bytes memory initData = abi.encodeWithSelector(
            HarborCustomFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            HarborCustomFeedAndRateAggregator_v1.RateSource.WSTETH,
            customFeeds,
            address(mockUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedAndRateAggregator_v1(address(proxy));

        assertEq(oracle.decimals(), 18, "Decimals should always be 18");
    }

    function test_InvalidRate_TooLow() public {
        HarborCustomFeedAndRateAggregator_v1 implementation = new HarborCustomFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        address[] memory customFeeds = new address[](mockStockFeeds.length);
        for (uint256 i = 0; i < mockStockFeeds.length; i++) {
            customFeeds[i] = address(mockStockFeeds[i]);
        }

        // Set invalid rate (too low: < 1e18)
        mockWstEth.setStEthPerToken(9e17); // 0.9

        bytes memory initData = abi.encodeWithSelector(
            HarborCustomFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            HarborCustomFeedAndRateAggregator_v1.RateSource.WSTETH,
            customFeeds,
            address(mockUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedAndRateAggregator_v1(address(proxy));

        vm.expectRevert(abi.encodeWithSelector(HarborCustomFeedAndRateAggregator_v1.InvalidRate.selector, 9e17));
        oracle.latestAnswer();
    }

    function test_InvalidRate_TooHigh() public {
        HarborCustomFeedAndRateAggregator_v1 implementation = new HarborCustomFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        address[] memory customFeeds = new address[](mockStockFeeds.length);
        for (uint256 i = 0; i < mockStockFeeds.length; i++) {
            customFeeds[i] = address(mockStockFeeds[i]);
        }

        // Set invalid rate (too high: > 2e18)
        mockWstEth.setStEthPerToken(21e17); // 2.1

        bytes memory initData = abi.encodeWithSelector(
            HarborCustomFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            HarborCustomFeedAndRateAggregator_v1.RateSource.WSTETH,
            customFeeds,
            address(mockUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedAndRateAggregator_v1(address(proxy));

        vm.expectRevert(abi.encodeWithSelector(HarborCustomFeedAndRateAggregator_v1.InvalidRate.selector, 21e17));
        oracle.latestAnswer();
    }

    function test_StaleRateSource() public {
        MockAggregatorV3 mockRateFeed = new MockAggregatorV3(18);
        // Set stale timestamp (more than 1 day old)
        // Advance block.timestamp to ensure we can set a stale timestamp
        vm.warp(3 days);
        uint256 staleTimestamp = block.timestamp - 2 days; // 2 days ago, definitely stale
        mockRateFeed.setAnswer(12e17, staleTimestamp);

        HarborCustomFeedAndRateAggregator_v1 implementation = new HarborCustomFeedAndRateAggregator_v1(
            address(0), // WSTETH not used
            address(0), // FXSAVE not used
            address(0), // SUSDE not used
            address(mockRateFeed) // WSTETH_CHAINLINK
        );

        address[] memory customFeeds = new address[](mockStockFeeds.length);
        for (uint256 i = 0; i < mockStockFeeds.length; i++) {
            customFeeds[i] = address(mockStockFeeds[i]);
        }

        bytes memory initData = abi.encodeWithSelector(
            HarborCustomFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            HarborCustomFeedAndRateAggregator_v1.RateSource.WSTETH_CHAINLINK,
            customFeeds,
            address(mockUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedAndRateAggregator_v1(address(proxy));

        vm.expectRevert(
            abi.encodeWithSelector(
                HarborCustomFeedAndRateAggregator_v1.StaleRateSource.selector,
                address(mockRateFeed),
                staleTimestamp
            )
        );
        oracle.latestAnswer();
    }

    /*//////////////////////////////////////////////////////////////
                            UPGRADE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Upgrade_Success() public {
        // Deploy V1 implementation and proxy
        HarborCustomFeedAndRateAggregator_v1 implementationV1 = new HarborCustomFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        address[] memory customFeeds = new address[](mockStockFeeds.length);
        for (uint256 i = 0; i < mockStockFeeds.length; i++) {
            customFeeds[i] = address(mockStockFeeds[i]);
        }

        bytes memory initData = abi.encodeWithSelector(
            HarborCustomFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            HarborCustomFeedAndRateAggregator_v1.RateSource.WSTETH,
            customFeeds,
            address(mockUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementationV1), initData);
        oracle = HarborCustomFeedAndRateAggregator_v1(address(proxy));

        // Store some state before upgrade
        string memory oracleNameBefore = oracle.oracleName();
        address ownerBefore = oracle.owner();
        uint256 priceBefore = oracle.getPrice();
        uint256 customFeedCountBefore = oracle.getCustomFeedCount();

        // Get V1 implementation address
        bytes32 implSlot = vm.load(address(proxy), IMPLEMENTATION_SLOT);
        address implV1 = address(uint160(uint256(implSlot)));
        assertEq(implV1, address(implementationV1), "V1 implementation should be set");

        // Deploy V2 implementation
        HarborCustomFeedAndRateAggregator_v2 implementationV2 = new HarborCustomFeedAndRateAggregator_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        // Upgrade to V2
        vm.expectEmit(true, false, false, false);
        emit HarborCustomFeedAndRateAggregator_v1.Upgraded(address(implementationV2));

        vm.prank(owner);
        oracle.upgradeToAndCall(address(implementationV2), "");

        // Verify implementation changed
        implSlot = vm.load(address(proxy), IMPLEMENTATION_SLOT);
        address implV2 = address(uint160(uint256(implSlot)));
        assertEq(implV2, address(implementationV2), "V2 implementation should be set");
        assertTrue(implV2 != implV1, "Implementation should have changed");

        // Verify storage is preserved
        assertEq(oracle.oracleName(), oracleNameBefore, "Oracle name should be preserved");
        assertEq(oracle.owner(), ownerBefore, "Owner should be preserved");
        assertEq(oracle.getCustomFeedCount(), customFeedCountBefore, "Custom feed count should be preserved");

        // Verify functionality still works
        uint256 priceAfter = oracle.getPrice();
        assertEq(priceAfter, priceBefore, "Price should be unchanged after upgrade");
    }

    function test_Upgrade_Revert_NonOwner() public {
        // Deploy V1 implementation and proxy
        HarborCustomFeedAndRateAggregator_v1 implementationV1 = new HarborCustomFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        address[] memory customFeeds = new address[](mockStockFeeds.length);
        for (uint256 i = 0; i < mockStockFeeds.length; i++) {
            customFeeds[i] = address(mockStockFeeds[i]);
        }

        bytes memory initData = abi.encodeWithSelector(
            HarborCustomFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            HarborCustomFeedAndRateAggregator_v1.RateSource.WSTETH,
            customFeeds,
            address(mockUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementationV1), initData);
        oracle = HarborCustomFeedAndRateAggregator_v1(address(proxy));

        // Deploy V2 implementation
        HarborCustomFeedAndRateAggregator_v2 implementationV2 = new HarborCustomFeedAndRateAggregator_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        // Try to upgrade as non-owner
        address nonOwner = address(0x1234);
        vm.prank(nonOwner);
        vm.expectRevert(); // Should revert due to onlyOwner modifier
        oracle.upgradeToAndCall(address(implementationV2), "");
    }

    function test_Upgrade_PreservesState() public {
        // Deploy V1 implementation and proxy
        HarborCustomFeedAndRateAggregator_v1 implementationV1 = new HarborCustomFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        address[] memory customFeeds = new address[](mockStockFeeds.length);
        for (uint256 i = 0; i < mockStockFeeds.length; i++) {
            customFeeds[i] = address(mockStockFeeds[i]);
        }

        bytes memory initData = abi.encodeWithSelector(
            HarborCustomFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            HarborCustomFeedAndRateAggregator_v1.RateSource.WSTETH,
            customFeeds,
            address(mockUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementationV1), initData);
        oracle = HarborCustomFeedAndRateAggregator_v1(address(proxy));

        // Update some state before upgrade
        uint64 newMaxAge = 7200;
        uint256 newMaxDev = 10e16;
        vm.prank(owner);
        oracle.updateCustomFeedConstraints(newMaxAge, newMaxDev);
        vm.prank(owner);
        oracle.updateUsdFeedConstraints(newMaxAge, newMaxDev);

        // Store state values before upgrade
        string memory oracleNameBefore = oracle.oracleName();
        address ownerBefore = oracle.owner();
        address usdFeedBefore = oracle.usdFeed();
        uint256 aggregationDivisorBefore = oracle.aggregationDivisor();
        uint256 customFeedCountBefore = oracle.getCustomFeedCount();
        (uint64 maxAgeCustomBefore, uint256 maxDevCustomBefore) = oracle.getConstraints(1);
        (uint64 maxAgeUsdBefore, uint256 maxDevUsdBefore) = oracle.getConstraints(100);

        // Deploy V2 implementation
        HarborCustomFeedAndRateAggregator_v2 implementationV2 = new HarborCustomFeedAndRateAggregator_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        // Upgrade to V2
        vm.prank(owner);
        oracle.upgradeToAndCall(address(implementationV2), "");

        // Verify all state is preserved
        assertEq(oracle.oracleName(), oracleNameBefore, "Oracle name should be preserved");
        assertEq(oracle.owner(), ownerBefore, "Owner should be preserved");
        assertEq(oracle.usdFeed(), usdFeedBefore, "USD feed should be preserved");
        assertEq(oracle.aggregationDivisor(), aggregationDivisorBefore, "Aggregation divisor should be preserved");
        assertEq(oracle.getCustomFeedCount(), customFeedCountBefore, "Custom feed count should be preserved");

        // Verify custom feed addresses are preserved (check against mockStockFeeds directly to avoid stack issues)
        for (uint256 i = 0; i < customFeedCountBefore; i++) {
            assertEq(oracle.getCustomFeed(i), address(mockStockFeeds[i]), "Custom feed address should be preserved");
        }

        // Verify constraints are preserved
        (uint64 maxAgeCustomAfter, uint256 maxDevCustomAfter) = oracle.getConstraints(1);
        (uint64 maxAgeUsdAfter, uint256 maxDevUsdAfter) = oracle.getConstraints(100);
        assertEq(maxAgeCustomAfter, maxAgeCustomBefore, "Custom feed max age should be preserved");
        assertEq(maxDevCustomAfter, maxDevCustomBefore, "Custom feed max dev should be preserved");
        assertEq(maxAgeUsdAfter, maxAgeUsdBefore, "USD feed max age should be preserved");
        assertEq(maxDevUsdAfter, maxDevUsdBefore, "USD feed max dev should be preserved");
    }
}
