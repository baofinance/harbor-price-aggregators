// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {HarborCustomFeedNormalization_v2} from "src/price/HarborCustomFeedNormalization_v2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {MockWstETH} from "test/price/HarborCustomFeedAndRateAggregator_v2.t.sol";
import {MockFxSAVE} from "test/price/HarborCustomFeedAndRateAggregator_v2.t.sol";
import {MockAggregatorV3} from "test/price/HarborCustomFeedAndRateAggregator_v2.t.sol";

contract HarborCustomFeedNormalization_v2Test is Test {
    HarborCustomFeedNormalization_v2 oracle;
    MockWstETH mockWstEth;
    MockFxSAVE mockFxSave;
    MockAggregatorV3[] mockMemeFeeds;
    MockAggregatorV3 mockStethUsdFeed;
    MockAggregatorV3 mockWstethStethFeed;

    address owner = address(this);
    uint64 maxAge = 3600; // 1 hour
    uint256 maxDev = 5e16; // 5%

    // Test data - meme coin prices in USD (8 decimals)
    // These represent current market prices (based on max supply normalization)
    int256[5] memePrices = [
        int256(13300000), // DOGE: $0.133 (8 decimals) - will normalize to ~$22.33
        int256(75), // SHIB: $0.0000075 (8 decimals, very small) - will normalize to ~$4.41
        int256(41), // PEPE: $0.0000041 (8 decimals, very small) - will normalize to ~$1.70
        int256(510000000), // TRUMP: $5.10 (8 decimals) - minimal change, stays ~$5.10
        int256(348000000) // WIF: $0.348 (8 decimals) - reference, no change
    ];

    // Normalization factors (in 18 decimals) - multipliers to normalize to WIF max supply (~998.84M)
    // Based on Max Supply (not circ. supply):
    // DOGE: Max = Unlimited, use circ. ~168B, factor = 168.2e18 (normalize to ~$22.33 from $0.133)
    // SHIB: Max = ~589.5T, factor = 589.5e18 (normalize to ~$4.41 from $0.0000075)
    // PEPE: Max = 420.69T, factor = 421e18 (normalize to ~$1.70 from $0.0000041)
    // TRUMP: Max = 1B, factor = ~0.99884e18 (minimal change, ~$5.10 stays ~$5.10)
    // WIF: Max = ~998.84M, factor = 1e18 (reference, no change)
    uint256[5] normalizationFactors = [
        168200000000000000000, // DOGE: 168.2e18
        589500000000000000000000, // SHIB: 589500e18 (corrected: 1000x larger)
        421000000000000000000000, // PEPE: 421000e18 (corrected: 1000x larger)
        998840000000000000, // TRUMP: ~0.99884e18 (minimal change)
        1000000000000000000 // WIF: 1e18 (no change)
    ];

    // Expected normalized prices (in 18 decimals) after applying factors based on max supply
    // DOGE: $0.133 * 168.2 = ~$22.33
    // SHIB: $0.0000075 * 589,500 = ~$4.41
    // PEPE: $0.0000041 * 421,000 = ~$1.70
    // TRUMP: $5.10 * 0.99884 ≈ $5.10 (minimal change)
    // WIF: $0.348 * 1 = $0.348 (no change)

    int256 stethUsdPrice = 283214000000; // 2832.14 USD/stETH with 8 decimals
    uint256 wstethStethRate = 1208351172000448378; // 1.208... stETH/wstETH (18 decimals)
    uint8 feedDecimals = 8;
    uint256 aggregationDivisor = 5; // Average of 5 coins

    function setUp() public {
        // Deploy mocks
        mockWstEth = new MockWstETH();
        mockFxSave = new MockFxSAVE();
        mockStethUsdFeed = new MockAggregatorV3(feedDecimals);
        mockWstethStethFeed = new MockAggregatorV3(18); // wstETH/stETH feed uses 18 decimals

        // Set mock values
        mockStethUsdFeed.setAnswer(stethUsdPrice, block.timestamp);
        mockWstethStethFeed.setAnswer(int256(wstethStethRate), block.timestamp);

        // Deploy meme coin feed mocks
        for (uint256 i = 0; i < memePrices.length; i++) {
            MockAggregatorV3 feed = new MockAggregatorV3(feedDecimals);
            feed.setAnswer(memePrices[i], block.timestamp);
            mockMemeFeeds.push(feed);
        }
    }

    function test_Normalization_Deployment() public {
        HarborCustomFeedNormalization_v2 implementation = new HarborCustomFeedNormalization_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used
            address(mockWstethStethFeed)
        );

        address[] memory customFeeds = new address[](mockMemeFeeds.length);
        for (uint256 i = 0; i < mockMemeFeeds.length; i++) {
            customFeeds[i] = address(mockMemeFeeds[i]);
        }

        uint256[] memory factors = new uint256[](normalizationFactors.length);
        for (uint256 i = 0; i < normalizationFactors.length; i++) {
            factors[i] = normalizationFactors[i];
        }

        bytes memory initData = abi.encodeWithSelector(
            HarborCustomFeedNormalization_v2.initialize.selector,
            owner,
            "stETHToBagm",
            HarborCustomFeedNormalization_v2.RateSource.WSTETH_CHAINLINK,
            customFeeds,
            factors,
            address(mockStethUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev,
            false
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedNormalization_v2(address(proxy));

        assertEq(oracle.owner(), owner, "Incorrect owner");
        assertTrue(bytes(oracle.oracleName()).length > 0, "Oracle name should not be empty");
        assertEq(oracle.aggregationDivisor(), aggregationDivisor, "Incorrect aggregation divisor");
        assertEq(oracle.getCustomFeedCount(), 5, "Should have 5 custom feeds");
    }

    function test_Normalization_PriceCalculation() public {
        // Deploy and initialize oracle
        HarborCustomFeedNormalization_v2 implementation = new HarborCustomFeedNormalization_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(mockWstethStethFeed)
        );

        address[] memory customFeeds = new address[](mockMemeFeeds.length);
        for (uint256 i = 0; i < mockMemeFeeds.length; i++) {
            customFeeds[i] = address(mockMemeFeeds[i]);
        }

        uint256[] memory factors = new uint256[](normalizationFactors.length);
        for (uint256 i = 0; i < normalizationFactors.length; i++) {
            factors[i] = normalizationFactors[i];
        }

        bytes memory initData = abi.encodeWithSelector(
            HarborCustomFeedNormalization_v2.initialize.selector,
            owner,
            "stETHToBagm",
            HarborCustomFeedNormalization_v2.RateSource.WSTETH_CHAINLINK,
            customFeeds,
            factors,
            address(mockStethUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev,
            false
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedNormalization_v2(address(proxy));

        // Calculate expected normalized prices manually
        // All prices are normalized to 18 decimals first, then normalized by factor

        // DOGE: $0.133 (8 decimals) -> 0.133e18 (18 decimals) -> 0.133e18 * 168.2e18 / 1e18
        uint256 dogePrice18 = uint256(memePrices[0]) * 1e10; // Convert 8 to 18 decimals
        uint256 dogeNormalized = Math.mulDiv(dogePrice18, normalizationFactors[0], 1e18);
        console.log("DOGE normalized:", dogeNormalized);

        // SHIB: $0.0000075 (8 decimals) -> 0.0000075e18 (18 decimals) -> 0.0000075e18 * 589.5e18 / 1e18
        uint256 shibPrice18 = uint256(memePrices[1]) * 1e10;
        uint256 shibNormalized = Math.mulDiv(shibPrice18, normalizationFactors[1], 1e18);
        console.log("SHIB normalized:", shibNormalized);

        // PEPE: $0.0000041 (8 decimals) -> 0.0000041e18 (18 decimals) -> 0.0000041e18 * 421e18 / 1e18
        uint256 pepePrice18 = uint256(memePrices[2]) * 1e10;
        uint256 pepeNormalized = Math.mulDiv(pepePrice18, normalizationFactors[2], 1e18);
        console.log("PEPE normalized:", pepeNormalized);

        // TRUMP: $5.10 (8 decimals) -> 5.10e18 (18 decimals) -> 5.10e18 * 5e18 / 1e18 (multiply by 5)
        uint256 trumpPrice18 = uint256(memePrices[3]) * 1e10;
        uint256 trumpNormalized = Math.mulDiv(trumpPrice18, normalizationFactors[3], 1e18);
        console.log("TRUMP normalized:", trumpNormalized);

        // WIF: $0.348 (8 decimals) -> 0.348e18 (18 decimals) -> 0.348e18 * 1e18 / 1e18 (no change)
        uint256 wifPrice18 = uint256(memePrices[4]) * 1e10;
        uint256 wifNormalized = Math.mulDiv(wifPrice18, normalizationFactors[4], 1e18);
        console.log("WIF normalized:", wifNormalized);

        // Sum normalized prices
        uint256 aggregatedNormalized = dogeNormalized +
            shibNormalized +
            pepeNormalized +
            trumpNormalized +
            wifNormalized;
        console.log("Aggregated normalized:", aggregatedNormalized);

        // Average (divide by 5)
        uint256 averageNormalized = aggregatedNormalized / aggregationDivisor;
        console.log("Average normalized:", averageNormalized);

        // stETH/USD price (18 decimals)
        uint256 stethUsdPrice18 = uint256(stethUsdPrice) * 1e10;
        console.log("stETH/USD (18 decimals):", stethUsdPrice18);

        // Final price: stETH/basket = (stETH/USD) / (basket/USD)
        // invertPrice=false: (usdFeedPrice * 1e18) / normalizedAggregatedPrice
        uint256 expectedPrice = Math.mulDiv(stethUsdPrice18, 1e18, averageNormalized);
        console.log("Expected stETH/basket price:", expectedPrice);

        // Get actual price and rate from oracle
        uint256 actualPrice = oracle.getPrice();
        uint256 actualRate = oracle.getRate();
        console.log("Actual stETH/basket price:", actualPrice);
        console.log("Actual rate (wstETH/stETH):", actualRate);
        console.log("Actual rate formatted:", actualRate / 1e15, "e15");

        // Allow small tolerance for rounding differences (0.1%)
        uint256 tolerance = expectedPrice / 1000;
        assertApproxEqAbs(actualPrice, expectedPrice, tolerance, "Price calculation mismatch");
    }

    function test_Normalization_Factors() public {
        // Deploy and initialize oracle
        HarborCustomFeedNormalization_v2 implementation = new HarborCustomFeedNormalization_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(mockWstethStethFeed)
        );

        address[] memory customFeeds = new address[](mockMemeFeeds.length);
        for (uint256 i = 0; i < mockMemeFeeds.length; i++) {
            customFeeds[i] = address(mockMemeFeeds[i]);
        }

        uint256[] memory factors = new uint256[](normalizationFactors.length);
        for (uint256 i = 0; i < normalizationFactors.length; i++) {
            factors[i] = normalizationFactors[i];
        }

        bytes memory initData = abi.encodeWithSelector(
            HarborCustomFeedNormalization_v2.initialize.selector,
            owner,
            "stETHToBagm",
            HarborCustomFeedNormalization_v2.RateSource.WSTETH_CHAINLINK,
            customFeeds,
            factors,
            address(mockStethUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev,
            false
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedNormalization_v2(address(proxy));

        // Verify normalization factors are set correctly
        for (uint256 i = 0; i < customFeeds.length; i++) {
            uint256 factor = oracle.feedNormalizationFactors(customFeeds[i]);
            assertEq(factor, normalizationFactors[i], "Normalization factor mismatch");
        }
    }

    function test_Normalization_RateSource() public {
        // Deploy and initialize oracle with WSTETH_CHAINLINK rate source
        HarborCustomFeedNormalization_v2 implementation = new HarborCustomFeedNormalization_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(mockWstethStethFeed)
        );

        address[] memory customFeeds = new address[](mockMemeFeeds.length);
        for (uint256 i = 0; i < mockMemeFeeds.length; i++) {
            customFeeds[i] = address(mockMemeFeeds[i]);
        }

        uint256[] memory factors = new uint256[](normalizationFactors.length);
        for (uint256 i = 0; i < normalizationFactors.length; i++) {
            factors[i] = normalizationFactors[i];
        }

        bytes memory initData = abi.encodeWithSelector(
            HarborCustomFeedNormalization_v2.initialize.selector,
            owner,
            "stETHToBagm",
            HarborCustomFeedNormalization_v2.RateSource.WSTETH_CHAINLINK,
            customFeeds,
            factors,
            address(mockStethUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev,
            false
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedNormalization_v2(address(proxy));

        // Verify rate source
        assertEq(
            uint256(oracle.rateSource()),
            uint256(HarborCustomFeedNormalization_v2.RateSource.WSTETH_CHAINLINK),
            "Incorrect rate source"
        );

        // Get rate (should be wstETH/stETH rate from Chainlink feed)
        uint256 rate = oracle.getRate();
        console.log("Rate (wstETH/stETH):", rate);
        console.log("Rate (wstETH/stETH) formatted:", rate / 1e15, "e15");

        (uint256 minPrice, uint256 maxPrice, uint256 minRate, uint256 maxRate) = oracle.latestAnswer();
        assertEq(rate, wstethStethRate, "Rate should match wstETH/stETH feed");
        assertEq(minRate, wstethStethRate, "Rate should match wstETH/stETH feed");
        assertEq(maxRate, wstethStethRate, "Rate should match wstETH/stETH feed");
        assertEq(minPrice, maxPrice, "Min and max prices should be equal");
    }

    function test_Normalization_GetNormalizedFeedPrice() public {
        // Deploy and initialize oracle
        HarborCustomFeedNormalization_v2 implementation = new HarborCustomFeedNormalization_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(mockWstethStethFeed)
        );

        address[] memory customFeeds = new address[](mockMemeFeeds.length);
        for (uint256 i = 0; i < mockMemeFeeds.length; i++) {
            customFeeds[i] = address(mockMemeFeeds[i]);
        }

        uint256[] memory factors = new uint256[](normalizationFactors.length);
        for (uint256 i = 0; i < normalizationFactors.length; i++) {
            factors[i] = normalizationFactors[i];
        }

        bytes memory initData = abi.encodeWithSelector(
            HarborCustomFeedNormalization_v2.initialize.selector,
            owner,
            "stETHToBagm",
            HarborCustomFeedNormalization_v2.RateSource.WSTETH_CHAINLINK,
            customFeeds,
            factors,
            address(mockStethUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev,
            false
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedNormalization_v2(address(proxy));

        // Test normalized price for each feed
        for (uint256 i = 0; i < customFeeds.length; i++) {
            address feed = customFeeds[i];
            uint256 normalizedPrice = oracle.getNormalizedFeedPrice(feed);

            // Calculate expected normalized price
            int256 feedPrice = memePrices[i];
            uint256 feedPrice18 = uint256(feedPrice) * 1e10; // Convert 8 decimals to 18
            uint256 expectedNormalized = Math.mulDiv(feedPrice18, normalizationFactors[i], 1e18);

            // Calculate dollar prices (in 18 decimals)
            // Raw price is already in 18 decimals from feedPrice18
            // Normalized price is already in 18 decimals

            // Convert to dollar representation (divide by 1e18 to get dollar value)
            // For display, we'll show integer and fractional parts separately
            uint256 rawDollarsInt = feedPrice18 / 1e18;
            uint256 rawDollarsFrac = (feedPrice18 % 1e18) / 1e12; // 6 decimal places for display

            uint256 normDollarsInt = normalizedPrice / 1e18;
            uint256 normDollarsFrac = (normalizedPrice % 1e18) / 1e12; // 6 decimal places for display

            // Log feed name by index with expected normalized price (based on max supply normalization)
            if (i == 0) console.log("DOGE: normalized from $0.133 to ~$22.33 (max supply normalization)");
            else if (i == 1) console.log("SHIB: normalized from $0.0000075 to ~$4.41 (max supply normalization)");
            else if (i == 2) console.log("PEPE: normalized from $0.0000041 to ~$1.70 (max supply normalization)");
            else if (i == 3)
                console.log("TRUMP: normalized from $5.10 to ~$5.10 (minimal change, max supply normalization)");
            else if (i == 4) console.log("WIF: normalized from $0.348 to ~$0.348 (reference, no change)");

            console.log("  Raw price (18 decimals):", feedPrice18);
            console.log("  Raw price ($):", rawDollarsInt, ".", rawDollarsFrac);
            console.log("  Normalized price (18 decimals):", normalizedPrice);
            console.log("  Normalized price ($):", normDollarsInt, ".", normDollarsFrac);

            // Allow small tolerance for rounding
            uint256 tolerance = expectedNormalized / 10000; // 0.01%
            assertApproxEqAbs(normalizedPrice, expectedNormalized, tolerance, "Normalized price mismatch");
        }
    }

    function test_Normalization_UpdateFactor() public {
        // Deploy and initialize oracle
        HarborCustomFeedNormalization_v2 implementation = new HarborCustomFeedNormalization_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(mockWstethStethFeed)
        );

        address[] memory customFeeds = new address[](mockMemeFeeds.length);
        for (uint256 i = 0; i < mockMemeFeeds.length; i++) {
            customFeeds[i] = address(mockMemeFeeds[i]);
        }

        uint256[] memory factors = new uint256[](normalizationFactors.length);
        for (uint256 i = 0; i < normalizationFactors.length; i++) {
            factors[i] = normalizationFactors[i];
        }

        bytes memory initData = abi.encodeWithSelector(
            HarborCustomFeedNormalization_v2.initialize.selector,
            owner,
            "stETHToBagm",
            HarborCustomFeedNormalization_v2.RateSource.WSTETH_CHAINLINK,
            customFeeds,
            factors,
            address(mockStethUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev,
            false
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedNormalization_v2(address(proxy));

        // Update normalization factor for first feed
        uint256 newFactor = 200000000000000000000; // 200e18
        oracle.setNormalizationFactor(customFeeds[0], newFactor);

        uint256 updatedFactor = oracle.feedNormalizationFactors(customFeeds[0]);
        assertEq(updatedFactor, newFactor, "Normalization factor should be updated");
    }
}
