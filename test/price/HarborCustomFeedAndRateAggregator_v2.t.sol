// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {HarborCustomFeedAndRateAggregator_v2} from "@harbor-price/price/HarborCustomFeedAndRateAggregator_v2.sol";
import {IFxSAVE} from "@harbor-price/interfaces/IFxSAVE.sol";
import {IWstETH} from "@bao/interfaces/IWstETH.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

contract MockWstETH is IWstETH {
    uint256 private _stEthPerToken;

    function setStEthPerToken(uint256 rate) external {
        _stEthPerToken = rate;
    }

    function stEthPerToken() external view override returns (uint256) {
        return _stEthPerToken;
    }

    function getStETHByWstETH(uint256 wstETHAmount) external view override returns (uint256) {
        return (wstETHAmount * _stEthPerToken) / 1e18;
    }

    function getWstETHByStETH(uint256 stETHAmount) external view override returns (uint256) {
        return (stETHAmount * 1e18) / _stEthPerToken;
    }

    function tokensPerStEth() external view override returns (uint256) {
        return _stEthPerToken;
    }

    function allowance(address, address) external pure override returns (uint256) {
        return 0;
    }
    function approve(address, uint256) external pure override returns (bool) {
        return true;
    }
    function balanceOf(address) external pure override returns (uint256) {
        return 0;
    }
    function totalSupply() external pure override returns (uint256) {
        return 0;
    }
    function transfer(address, uint256) external pure override returns (bool) {
        return true;
    }
    function transferFrom(address, address, uint256) external pure override returns (bool) {
        return true;
    }
}

contract MockFxSAVE is IFxSAVE {
    uint256 private _assetsPerShare;

    function setAssetsPerShare(uint256 rate) external {
        _assetsPerShare = rate;
    }

    function convertToAssets(uint256 shares) external view override returns (uint256) {
        return (shares * _assetsPerShare) / 1e18;
    }

    // IERC4626 functions (stubs)
    function asset() external pure override returns (address) {
        return address(0);
    }
    function convertToShares(uint256) external pure override returns (uint256) {
        return 0;
    }
    function deposit(uint256, address) external pure override returns (uint256) {
        return 0;
    }
    function maxDeposit(address) external pure override returns (uint256) {
        return 0;
    }
    function maxMint(address) external pure override returns (uint256) {
        return 0;
    }
    function maxRedeem(address) external pure override returns (uint256) {
        return 0;
    }
    function maxWithdraw(address) external pure override returns (uint256) {
        return 0;
    }
    function mint(uint256, address) external pure override returns (uint256) {
        return 0;
    }
    function previewDeposit(uint256) external pure override returns (uint256) {
        return 0;
    }
    function previewMint(uint256) external pure override returns (uint256) {
        return 0;
    }
    function previewRedeem(uint256) external pure override returns (uint256) {
        return 0;
    }
    function previewWithdraw(uint256) external pure override returns (uint256) {
        return 0;
    }
    function redeem(uint256, address, address) external pure override returns (uint256) {
        return 0;
    }
    function totalAssets() external pure override returns (uint256) {
        return 0;
    }
    function withdraw(uint256, address, address) external pure override returns (uint256) {
        return 0;
    }

    // IERC20Metadata stubs
    function name() external pure override returns (string memory) {
        return "";
    }
    function symbol() external pure override returns (string memory) {
        return "";
    }
    function decimals() external pure override returns (uint8) {
        return 18;
    }

    // IERC20 stubs
    function allowance(address, address) external pure override returns (uint256) {
        return 0;
    }
    function approve(address, uint256) external pure override returns (bool) {
        return true;
    }
    function balanceOf(address) external pure override returns (uint256) {
        return 0;
    }
    function totalSupply() external pure override returns (uint256) {
        return 0;
    }
    function transfer(address, uint256) external pure override returns (bool) {
        return true;
    }
    function transferFrom(address, address, uint256) external pure override returns (bool) {
        return true;
    }

    // IFxSAVE-specific stubs
    function CLAIM_FOR_ROLE() external pure override returns (bytes32) {
        return bytes32(0);
    }
    function DEFAULT_ADMIN_ROLE() external pure override returns (bytes32) {
        return bytes32(0);
    }
    function DOMAIN_SEPARATOR() external pure override returns (bytes32) {
        return bytes32(0);
    }
    function base() external pure override returns (address) {
        return address(0);
    }
    function gauge() external pure override returns (address) {
        return address(0);
    }
    function getExpenseRatio() external pure override returns (uint256) {
        return 0;
    }
    function getHarvesterRatio() external pure override returns (uint256) {
        return 0;
    }
    function getRoleAdmin(bytes32) external pure override returns (bytes32) {
        return bytes32(0);
    }
    function getThreshold() external pure override returns (uint256) {
        return 0;
    }
    function harvester() external pure override returns (address) {
        return address(0);
    }
    function hasRole(bytes32, address) external pure override returns (bool) {
        return false;
    }
    function lockedProxy(address) external pure override returns (address) {
        return address(0);
    }
    function nav() external pure override returns (uint256) {
        return 0;
    }
    function nonces(address) external pure override returns (uint256) {
        return 0;
    }
    function supportsInterface(bytes4) external pure override returns (bool) {
        return false;
    }
    function treasury() external pure override returns (address) {
        return address(0);
    }
    function vault() external pure override returns (address) {
        return address(0);
    }
    function eip712Domain()
        external
        pure
        override
        returns (bytes1, string memory, string memory, uint256, address, bytes32, uint256[] memory)
    {
        return (bytes1(0), "", "", 0, address(0), bytes32(0), new uint256[](0));
    }
}

contract MockAggregatorV3 is AggregatorV3Interface {
    uint8 private _decimals;
    int256 private _answer;
    uint80 private _roundId;
    uint256 private _updatedAt;

    constructor(uint8 decimals_) {
        _decimals = decimals_;
    }

    function setAnswer(int256 answer_, uint256 updatedAt_) external {
        _answer = answer_;
        _updatedAt = updatedAt_;
        _roundId++;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, _answer, 0, _updatedAt, _roundId);
    }

    function description() external pure override returns (string memory) {
        return "";
    }
    function version() external pure override returns (uint256) {
        return 1;
    }
    function getRoundData(
        uint80
    )
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, _answer, 0, _updatedAt, _roundId);
    }
}

contract HarborCustomFeedAndRateAggregator_v2Test is Test {
    HarborCustomFeedAndRateAggregator_v2 oracle;
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
        HarborCustomFeedAndRateAggregator_v2 implementation = new HarborCustomFeedAndRateAggregator_v2(
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
            HarborCustomFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "WstETHToAggregatedStocks",
            HarborCustomFeedAndRateAggregator_v2.RateSource.WSTETH,
            customFeeds,
            address(mockUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev,
            false // invertPrice
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedAndRateAggregator_v2(address(proxy));

        assertEq(oracle.owner(), owner, "Incorrect owner");
        assertTrue(bytes(oracle.oracleName()).length > 0, "Oracle name should not be empty");
        assertEq(oracle.getCustomFeedCount(), mockStockFeeds.length, "Incorrect custom feed count");
        assertEq(oracle.aggregationDivisor(), aggregationDivisor, "Incorrect aggregation divisor");
        assertEq(oracle.version(), 2, "Version should be 2");
    }

    function test_GetPrice() public {
        HarborCustomFeedAndRateAggregator_v2 implementation = new HarborCustomFeedAndRateAggregator_v2(
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
            HarborCustomFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "TestOracle",
            HarborCustomFeedAndRateAggregator_v2.RateSource.WSTETH,
            customFeeds,
            address(mockUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev,
            false // invertPrice
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedAndRateAggregator_v2(address(proxy));

        uint256 price = oracle.getPrice();
        (uint256 minPrice, uint256 maxPrice, uint256 minRate, ) = oracle.latestAnswer();

        console.log("=== wstETH Custom Feed Price (V2) ===");
        console.log("Price (units per 1 USD):", price);
        console.log("Min Price:", minPrice);
        console.log("Max Price:", maxPrice);
        console.log("wstETH Rate (wstETH/stETH):", minRate);

        // Calculate expected price manually (V2: no rate multiplication)
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
        console.log("=== Stock Basket Units per 1 USD (V2) ===");
        console.log("Aggregated stock price (average of 6 stocks):", normalizedAggregatedPrice);
        console.log("USD feed price:", normalizedUsdPrice);
        // V2: Direct conversion without rate multiplication
        // Calculate expected: (usdFeedPrice * 1e18) / aggregated_price
        uint256 expectedPrice = Math.mulDiv(normalizedUsdPrice, 1e18, normalizedAggregatedPrice);
        console.log("Expected units:", expectedPrice);

        assertTrue(price > 0, "Price should be positive");
        assertEq(price, expectedPrice, "Incorrect aggregated price (V2 - no rate)");
    }

    function test_LatestAnswer() public {
        HarborCustomFeedAndRateAggregator_v2 implementation = new HarborCustomFeedAndRateAggregator_v2(
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
            HarborCustomFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "TestOracle",
            HarborCustomFeedAndRateAggregator_v2.RateSource.WSTETH,
            customFeeds,
            address(mockUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev,
            false // invertPrice
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedAndRateAggregator_v2(address(proxy));

        (uint256 minPrice, uint256 maxPrice, uint256 minRate, uint256 maxRate) = oracle.latestAnswer();

        assertEq(minPrice, maxPrice, "Min/max price mismatch");
        assertEq(minRate, maxRate, "Min/max rate mismatch");
        assertEq(minRate, wstEthRate, "Incorrect rate");
        assertTrue(minPrice > 0, "Price should be positive");
    }

    function test_UpdateCustomFeedConstraints() public {
        HarborCustomFeedAndRateAggregator_v2 implementation = new HarborCustomFeedAndRateAggregator_v2(
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
            HarborCustomFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "TestOracle",
            HarborCustomFeedAndRateAggregator_v2.RateSource.WSTETH,
            customFeeds,
            address(mockUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev,
            false // invertPrice
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedAndRateAggregator_v2(address(proxy));

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
        HarborCustomFeedAndRateAggregator_v2 implementation = new HarborCustomFeedAndRateAggregator_v2(
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
            HarborCustomFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "TestOracle",
            HarborCustomFeedAndRateAggregator_v2.RateSource.WSTETH,
            customFeeds,
            address(mockUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev,
            false // invertPrice
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedAndRateAggregator_v2(address(proxy));

        uint64 newMaxAge = 7200; // 2 hours
        uint256 newMaxDev = 10e16; // 10%

        vm.prank(owner);
        oracle.updateUsdFeedConstraints(newMaxAge, newMaxDev);

        (uint64 maxAge_, uint256 maxDev_) = oracle.getConstraints(100);
        assertEq(maxAge_, newMaxAge, "Incorrect maxAge for USD feed");
        assertEq(maxDev_, newMaxDev, "Incorrect maxDev for USD feed");
    }

    function test_GetCustomFeed() public {
        HarborCustomFeedAndRateAggregator_v2 implementation = new HarborCustomFeedAndRateAggregator_v2(
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
            HarborCustomFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "TestOracle",
            HarborCustomFeedAndRateAggregator_v2.RateSource.WSTETH,
            customFeeds,
            address(mockUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev,
            false // invertPrice
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedAndRateAggregator_v2(address(proxy));

        for (uint256 i = 0; i < customFeeds.length; i++) {
            address feed = oracle.getCustomFeed(i);
            assertEq(feed, customFeeds[i], "Incorrect custom feed address");
        }
    }

    function test_Fuzz_WstETH_Rate(uint256 rateInput) public {
        // Bound wstETH rate to [1.0, 1.3] in 1e18
        uint256 rate = bound(rateInput, 1e18, 13e17);
        mockWstEth.setStEthPerToken(rate);

        HarborCustomFeedAndRateAggregator_v2 implementation = new HarborCustomFeedAndRateAggregator_v2(
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
            HarborCustomFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "TestOracle",
            HarborCustomFeedAndRateAggregator_v2.RateSource.WSTETH,
            customFeeds,
            address(mockUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev,
            false // invertPrice
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedAndRateAggregator_v2(address(proxy));

        (, , uint256 minRate, uint256 maxRate) = oracle.latestAnswer();
        assertEq(minRate, rate, "Incorrect rate (fuzz)");
        assertEq(maxRate, rate, "Rate mismatch (fuzz)");
    }

    function test_V2_Price_NoRateMultiplication() public {
        // Test that V2 does NOT multiply by rate
        HarborCustomFeedAndRateAggregator_v2 implementation = new HarborCustomFeedAndRateAggregator_v2(
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
            HarborCustomFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "TestOracle",
            HarborCustomFeedAndRateAggregator_v2.RateSource.WSTETH,
            customFeeds,
            address(mockUsdFeed),
            aggregationDivisor,
            maxAge,
            maxDev,
            maxAge,
            maxDev,
            false // invertPrice
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborCustomFeedAndRateAggregator_v2(address(proxy));

        uint256 price = oracle.getPrice();

        // V2: price = (usdFeedPrice * 1e18) / normalizedAggregatedPrice (no rate multiplication)
        uint256 aggregatedPrice = 0;
        for (uint256 i = 0; i < stockPrices.length; i++) {
            aggregatedPrice += uint256(stockPrices[i]) * 1e10;
        }
        uint256 normalizedAggregatedPrice = aggregatedPrice / aggregationDivisor;
        uint256 normalizedUsdPrice = uint256(usdPrice) * 1e10;
        uint256 expectedPrice = Math.mulDiv(normalizedUsdPrice, 1e18, normalizedAggregatedPrice);

        console.log("Price (V2 NoRateMultiplication):", price);
        console.log("Expected Price:", expectedPrice);
        assertEq(price, expectedPrice, "V2 price should not multiply by rate");

        // Verify rate is still returned correctly
        uint256 rate = oracle.getRate();
        console.log("Rate:", rate);
        assertEq(rate, wstEthRate, "Rate should still be correct");
    }
}
