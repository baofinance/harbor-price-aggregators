// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {HarborSingleFeedAndRateAggregator_v2} from "@harbor-price/price/HarborSingleFeedAndRateAggregator_v2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MockWstETH} from "test/mock/MockWstETH.sol";
import {MockFxSAVE} from "test/mock/MockFxSAVE.sol";
import {MockAggregatorV3} from "test/mock/MockAggregatorV3.sol";

contract HarborSingleFeedAndRateAggregator_v2Test is Test {
    HarborSingleFeedAndRateAggregator_v2 oracle;
    MockWstETH mockWstEth;
    MockFxSAVE mockFxSave;
    MockAggregatorV3 mockEthUsdFeed;

    address owner = address(this);
    uint64 maxAge = 3600; // 1 hour
    uint256 maxDev = 5e16; // 5%

    // Test data
    uint256 wstEthRate = 1208351172000448378; // 1.208... stETH/wstETH
    int256 ethUsdPrice = 400000000000; // 4000 USD/ETH with 8 decimals
    uint8 ethUsdDecimals = 8;

    // ERC1967 implementation slot
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function setUp() public {
        // Deploy mocks
        mockWstEth = new MockWstETH();
        mockFxSave = new MockFxSAVE();
        mockEthUsdFeed = new MockAggregatorV3(ethUsdDecimals);

        // Set mock values
        mockWstEth.setStEthPerToken(wstEthRate);
        mockFxSave.setAssetsPerShare(1052400000000000000); // 1.0524
        mockEthUsdFeed.setAnswer(ethUsdPrice, block.timestamp);
    }

    function test_WstETH_Deployment() public {
        // Deploy wstETH oracle (RateSource = 0 for wstETH)
        HarborSingleFeedAndRateAggregator_v2 implementation = new HarborSingleFeedAndRateAggregator_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0) // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborSingleFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "WstETHToETH",
            0,
            address(mockEthUsdFeed),
            1, // priceDivisor
            maxAge,
            maxDev,
            false // invertPrice
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborSingleFeedAndRateAggregator_v2(address(proxy));

        assertEq(oracle.owner(), owner, "Incorrect owner");
        assertTrue(bytes(oracle.oracleName()).length > 0, "Oracle name should not be empty");
        assertEq(oracle.version(), 2, "Version should be 2");
    }

    function test_FxSAVE_Deployment() public {
        // Deploy fxSAVE oracle (RateSource = 1 for fxSAVE)
        HarborSingleFeedAndRateAggregator_v2 implementation = new HarborSingleFeedAndRateAggregator_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0) // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborSingleFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "FxSAVEToETH",
            1,
            address(mockEthUsdFeed),
            1, // priceDivisor
            maxAge,
            maxDev,
            false // invertPrice
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborSingleFeedAndRateAggregator_v2(address(proxy));

        assertEq(oracle.owner(), owner, "Incorrect owner");
        assertTrue(bytes(oracle.oracleName()).length > 0, "Oracle name should not be empty");
        assertEq(oracle.version(), 2, "Version should be 2");
    }

    function test_WstETH_GetPrice() public {
        HarborSingleFeedAndRateAggregator_v2 implementation = new HarborSingleFeedAndRateAggregator_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0) // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborSingleFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "TestOracle",
            0,
            address(mockEthUsdFeed),
            1, // priceDivisor
            maxAge,
            maxDev,
            false // invertPrice
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborSingleFeedAndRateAggregator_v2(address(proxy));

        // V2: price = firstFeedPrice / priceDivisor (no rate multiplication)
        uint256 price = oracle.getPrice();
        // Expected: normalizedEthUsdPrice / priceDivisor
        // normalizedEthUsdPrice = 400000000000 * 1e10 = 4000000000000000000000
        // casting to 'uint256' is safe because ethUsdPrice is a positive price value
        uint256 normalizedEthUsdPrice = uint256(ethUsdPrice) * 1e10;
        uint256 expectedPrice = normalizedEthUsdPrice / 1; // priceDivisor = 1

        console.log("Price (wstETH):", price);
        assertEq(price, expectedPrice, "Incorrect wstETH price (V2 - no rate)");
    }

    function test_FxSAVE_LatestAnswer() public {
        uint256 fxsaveRate = 1052400000000000000; // 1.0524
        mockFxSave.setAssetsPerShare(fxsaveRate);

        HarborSingleFeedAndRateAggregator_v2 implementation = new HarborSingleFeedAndRateAggregator_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0) // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborSingleFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "FxSAVEToETH",
            1, // FXSAVE
            address(mockEthUsdFeed),
            1, // priceDivisor
            maxAge,
            maxDev,
            false // invertPrice
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborSingleFeedAndRateAggregator_v2(address(proxy));

        (uint256 minPrice, uint256 maxPrice, uint256 minRate, uint256 maxRate) = oracle.latestAnswer();

        console.log("Price (FxSAVE latestAnswer):", minPrice);
        console.log("Rate (FxSAVE):", minRate);
        assertEq(minPrice, maxPrice, "Min/max price mismatch");
        assertEq(minRate, maxRate, "Min/max rate mismatch");
        assertEq(minRate, fxsaveRate, "Incorrect rate");
        assertTrue(minPrice > 0, "Price should be positive");
    }

    function test_UpdateConstraints() public {
        HarborSingleFeedAndRateAggregator_v2 implementation = new HarborSingleFeedAndRateAggregator_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0) // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborSingleFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "TestOracle",
            0,
            address(mockEthUsdFeed),
            1, // priceDivisor
            maxAge,
            maxDev,
            false // invertPrice
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborSingleFeedAndRateAggregator_v2(address(proxy));

        uint64 newMaxAge = 7200; // 2 hours
        uint256 newMaxDev = 10e16; // 10%

        vm.prank(owner);
        oracle.setFeedConstraints(1, newMaxAge, newMaxDev);

        (uint64 maxAge_, uint256 maxDev_) = oracle.getConstraints(1);
        assertEq(maxAge_, newMaxAge, "Incorrect maxAge");
        assertEq(maxDev_, newMaxDev, "Incorrect maxDev");
    }

    function test_Fuzz_FxSAVE_Rate(uint256 rateInput) public {
        // Bound fxsave rate to [1.0, 1.1] in 1e18
        uint256 rate = bound(rateInput, 1e18, 11e17);
        mockFxSave.setAssetsPerShare(rate);

        HarborSingleFeedAndRateAggregator_v2 implementation = new HarborSingleFeedAndRateAggregator_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0) // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborSingleFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "FxSAVEToETH",
            1, // FXSAVE
            address(mockEthUsdFeed),
            1, // priceDivisor
            maxAge,
            maxDev,
            false // invertPrice
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborSingleFeedAndRateAggregator_v2(address(proxy));

        (, , uint256 minRate, uint256 maxRate) = oracle.latestAnswer();
        assertEq(minRate, rate, "Incorrect rate (fuzz)");
        assertEq(maxRate, rate, "Rate mismatch (fuzz)");
    }

    function test_V2_Price_NoRateMultiplication() public {
        // Test that V2 does NOT multiply by rate
        HarborSingleFeedAndRateAggregator_v2 implementation = new HarborSingleFeedAndRateAggregator_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborSingleFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "TestOracle",
            0, // WSTETH
            address(mockEthUsdFeed),
            1, // priceDivisor
            maxAge,
            maxDev,
            false, // invertPrice
            false // invertPrice
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborSingleFeedAndRateAggregator_v2(address(proxy));

        uint256 price = oracle.getPrice();

        // V2: price should be firstFeedPrice / priceDivisor (no rate multiplication)
        uint256 normalizedEthUsdPrice = uint256(ethUsdPrice) * 1e10;
        uint256 expectedPrice = normalizedEthUsdPrice / 1; // priceDivisor = 1

        console.log("Price (V2 NoRateMultiplication):", price);
        console.log("Expected Price:", expectedPrice);
        assertEq(price, expectedPrice, "V2 price should not multiply by rate");

        // Verify rate is still returned correctly
        uint256 rate = oracle.getRate();
        console.log("Rate:", rate);
        assertEq(rate, wstEthRate, "Rate should still be correct");
    }

    function test_InvertedPrice() public {
        // Test inverted price for fxUSD (USD-pegged token)
        // Feed: ETH/USD = 4000 means 4000 USD per ETH
        // Inverted: USD/ETH = 1/4000 = 0.00025 ETH per USD
        // Since fxUSD is pegged to USD, this gives us fxUSD/ETH

        HarborSingleFeedAndRateAggregator_v2 implementation = new HarborSingleFeedAndRateAggregator_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborSingleFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "FxUSDToETH",
            1, // FXSAVE
            address(mockEthUsdFeed),
            1, // priceDivisor
            maxAge,
            maxDev,
            true // invertPrice = true
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborSingleFeedAndRateAggregator_v2(address(proxy));

        uint256 price = oracle.getPrice();

        // Expected: 1e36 / normalizedEthUsdPrice
        uint256 normalizedEthUsdPrice = uint256(ethUsdPrice) * 1e10; // 4000 * 1e8 * 1e10 = 4000e18
        uint256 expectedPrice = (1e18 * 1e18) / normalizedEthUsdPrice; // 1e36 / 4000e18 = 0.00025e18

        console.log("Price (Inverted):", price);
        console.log("Expected Price (Inverted):", expectedPrice);
        console.log("Feed Price (ETH/USD):", normalizedEthUsdPrice);
        assertEq(price, expectedPrice, "Inverted price should be 1e36 / feedPrice");
        assertEq(price, 250000000000000, "Inverted price should be 0.00025 ETH per USD (0.00025e18)");

        // Verify the oracle has invertPrice set
        assertTrue(oracle.invertPrice(), "invertPrice should be true");
    }

    function test_SetInvertPrice() public {
        HarborSingleFeedAndRateAggregator_v2 implementation = new HarborSingleFeedAndRateAggregator_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborSingleFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "TestOracle",
            0,
            address(mockEthUsdFeed),
            1,
            maxAge,
            maxDev,
            false // invertPrice = false initially
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborSingleFeedAndRateAggregator_v2(address(proxy));

        assertFalse(oracle.invertPrice(), "invertPrice should be false initially");

        // Get normal price first
        uint256 normalPrice = oracle.getPrice();
        console.log("Price (Normal, before inversion):", normalPrice);

        // Set invertPrice to true
        oracle.setInvertPrice(true);
        assertTrue(oracle.invertPrice(), "invertPrice should be true after setting");

        // Verify price is now inverted
        uint256 price = oracle.getPrice();
        uint256 normalizedEthUsdPrice = uint256(ethUsdPrice) * 1e10;
        uint256 expectedInvertedPrice = (1e18 * 1e18) / normalizedEthUsdPrice;
        console.log("Price (Inverted, after setting):", price);
        console.log("Expected Inverted Price:", expectedInvertedPrice);
        assertEq(price, expectedInvertedPrice, "Price should be inverted after setting invertPrice");
    }
}
