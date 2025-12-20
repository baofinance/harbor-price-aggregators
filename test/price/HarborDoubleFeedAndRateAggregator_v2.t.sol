// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {HarborDoubleFeedAndRateAggregator_v2} from "src/price/HarborDoubleFeedAndRateAggregator_v2.sol";
import {IFxSAVE} from "src/interfaces/IFxSAVE.sol";
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

contract HarborDoubleFeedAndRateAggregator_v2Test is Test {
    HarborDoubleFeedAndRateAggregator_v2 oracle;
    MockWstETH mockWstEth;
    MockFxSAVE mockFxSave;
    MockAggregatorV3 mockFirstFeed;
    MockAggregatorV3 mockSecondFeed;

    address owner = address(this);
    uint64 maxAge = 3600; // 1 hour
    uint256 maxDev = 5e16; // 5%

    // Test data
    uint256 wstEthRate = 1208351172000448378; // 1.208... stETH/wstETH
    uint256 fxsaveRate = 1052400000000000000; // 1.0524
    int256 ethUsdPrice = 400000000000; // 4000 USD/ETH with 8 decimals
    int256 btcUsdPrice = 10000000000000; // 100000 USD/BTC with 8 decimals
    int256 usdcUsdPrice = 100000000; // 1.0 USD/USDC with 8 decimals
    uint8 feedDecimals = 8;

    // ERC1967 implementation slot
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    function setUp() public {
        // Deploy mocks
        mockWstEth = new MockWstETH();
        mockFxSave = new MockFxSAVE();
        mockFirstFeed = new MockAggregatorV3(feedDecimals);
        mockSecondFeed = new MockAggregatorV3(feedDecimals);

        // Set mock values
        mockWstEth.setStEthPerToken(wstEthRate);
        mockFxSave.setAssetsPerShare(fxsaveRate);
        mockFirstFeed.setAnswer(ethUsdPrice, block.timestamp);
        mockSecondFeed.setAnswer(btcUsdPrice, block.timestamp);
    }

    function test_WstETH_ToBTC_Deployment() public {
        // Deploy wstETH to BTC oracle (RateSource = 0 for wstETH, ETH/USD + BTC/USD)
        HarborDoubleFeedAndRateAggregator_v2 implementation = new HarborDoubleFeedAndRateAggregator_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0) // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborDoubleFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "WstETHToBTC",
            HarborDoubleFeedAndRateAggregator_v2.RateSource.WSTETH,
            address(mockFirstFeed), // ETH/USD
            address(mockSecondFeed), // BTC/USD
            1, // priceDivisor
            maxAge,
            maxDev,
            maxAge,
            maxDev,
            false // invertPrice
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborDoubleFeedAndRateAggregator_v2(address(proxy));

        assertEq(oracle.owner(), owner, "Incorrect owner");
        assertTrue(bytes(oracle.oracleName()).length > 0, "Oracle name should not be empty");
        assertEq(oracle.version(), 2, "Version should be 2");
    }

    function test_FxSAVE_ToBTC_Deployment() public {
        // Deploy fxSAVE to BTC oracle (RateSource = 1 for fxSAVE, USDC/USD + BTC/USD)
        mockFirstFeed.setAnswer(usdcUsdPrice, block.timestamp);

        HarborDoubleFeedAndRateAggregator_v2 implementation = new HarborDoubleFeedAndRateAggregator_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0) // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborDoubleFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "TestOracle",
            1,
            address(mockFirstFeed),
            address(mockSecondFeed),
            1, // priceDivisor
            maxAge,
            maxDev,
            maxAge,
            maxDev,
            false // invertPrice
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborDoubleFeedAndRateAggregator_v2(address(proxy));

        assertEq(oracle.owner(), owner, "Incorrect owner");
        assertTrue(bytes(oracle.oracleName()).length > 0, "Oracle name should not be empty");
        assertEq(oracle.version(), 2, "Version should be 2");
    }

    function test_GetPrice() public {
        HarborDoubleFeedAndRateAggregator_v2 implementation = new HarborDoubleFeedAndRateAggregator_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0) // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborDoubleFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "TestOracle",
            1,
            address(mockFirstFeed),
            address(mockSecondFeed),
            1, // priceDivisor
            maxAge,
            maxDev,
            maxAge,
            maxDev,
            false // invertPrice
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborDoubleFeedAndRateAggregator_v2(address(proxy));

        uint256 price = oracle.getPrice();
        console.log("Price (GetPrice):", price);
        assertTrue(price > 0, "Price should be positive");
    }

    function test_LatestAnswer() public {
        HarborDoubleFeedAndRateAggregator_v2 implementation = new HarborDoubleFeedAndRateAggregator_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0) // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborDoubleFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "TestOracle",
            1,
            address(mockFirstFeed),
            address(mockSecondFeed),
            1, // priceDivisor
            maxAge,
            maxDev,
            maxAge,
            maxDev,
            false // invertPrice
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborDoubleFeedAndRateAggregator_v2(address(proxy));

        (uint256 minPrice, uint256 maxPrice, uint256 minRate, uint256 maxRate) = oracle.latestAnswer();

        console.log("Price (LatestAnswer):", minPrice);
        console.log("Rate (LatestAnswer):", minRate);
        assertEq(minPrice, maxPrice, "Min/max price mismatch");
        assertEq(minRate, maxRate, "Min/max rate mismatch");
        assertEq(minRate, fxsaveRate, "Incorrect rate");
        assertTrue(minPrice > 0, "Price should be positive");
    }

    function test_UpdateBothConstraints() public {
        HarborDoubleFeedAndRateAggregator_v2 implementation = new HarborDoubleFeedAndRateAggregator_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0) // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborDoubleFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "TestOracle",
            1,
            address(mockFirstFeed),
            address(mockSecondFeed),
            1, // priceDivisor
            maxAge,
            maxDev,
            maxAge,
            maxDev,
            false // invertPrice
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborDoubleFeedAndRateAggregator_v2(address(proxy));

        uint64 newMaxAge1 = 7200;
        uint256 newMaxDev1 = 10e16;
        uint64 newMaxAge2 = 14400;
        uint256 newMaxDev2 = 15e16;

        vm.prank(owner);
        oracle.updateBothConstraints(newMaxAge1, newMaxDev1, newMaxAge2, newMaxDev2);

        (uint64 maxAge1, uint256 maxDev1) = oracle.getConstraints(1);
        (uint64 maxAge2, uint256 maxDev2) = oracle.getConstraints(2);

        assertEq(maxAge1, newMaxAge1, "Incorrect first feed maxAge");
        assertEq(maxDev1, newMaxDev1, "Incorrect first feed maxDev");
        assertEq(maxAge2, newMaxAge2, "Incorrect second feed maxAge");
        assertEq(maxDev2, newMaxDev2, "Incorrect second feed maxDev");
    }

    function test_Fuzz_FxSAVE_ToBTC(uint256 rateInput, uint256 btcPriceInput) public {
        // Bound fxsave rate to [1.0, 1.1] in 1e18
        uint256 rate = bound(rateInput, 1e18, 11e17);
        // Bound BTC/USD to [90000, 110000] in 8 decimals
        uint256 btcPrice = bound(btcPriceInput, 90000 * 1e8, 110000 * 1e8);

        mockFxSave.setAssetsPerShare(rate);
        mockFirstFeed.setAnswer(usdcUsdPrice, block.timestamp);
        // casting to 'int256' is safe because btcPrice is bounded to reasonable values
        mockSecondFeed.setAnswer(int256(btcPrice), block.timestamp);

        HarborDoubleFeedAndRateAggregator_v2 implementation = new HarborDoubleFeedAndRateAggregator_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0) // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborDoubleFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "TestOracle",
            1,
            address(mockFirstFeed),
            address(mockSecondFeed),
            1, // priceDivisor
            maxAge,
            maxDev,
            maxAge,
            maxDev,
            false // invertPrice
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborDoubleFeedAndRateAggregator_v2(address(proxy));

        (uint256 minPrice, , uint256 minRate, ) = oracle.latestAnswer();

        assertEq(minRate, rate, "Incorrect rate (fuzz)");
        assertTrue(minPrice > 0, "Price should be positive (fuzz)");
    }

    function test_V2_Price_NoRateMultiplication() public {
        // Test that V2 does NOT multiply by rate
        // Set first feed to USDC/USD for FXSAVE test
        mockFirstFeed.setAnswer(usdcUsdPrice, block.timestamp);

        HarborDoubleFeedAndRateAggregator_v2 implementation = new HarborDoubleFeedAndRateAggregator_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborDoubleFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "TestOracle",
            1, // FXSAVE
            address(mockFirstFeed),
            address(mockSecondFeed),
            1, // priceDivisor
            maxAge,
            maxDev,
            maxAge,
            maxDev,
            false // invertPrice
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborDoubleFeedAndRateAggregator_v2(address(proxy));

        uint256 price = oracle.getPrice();

        // V2: price = (firstFeedPrice * priceDivisor) / secondFeedPrice (no rate multiplication)
        uint256 normalizedFirstPrice = uint256(usdcUsdPrice) * 1e10;
        uint256 normalizedSecondPrice = uint256(btcUsdPrice) * 1e10;
        uint256 expectedPrice = Math.mulDiv(Math.mulDiv(normalizedFirstPrice, 1, 1), 1e18, normalizedSecondPrice);

        console.log("Price (V2 NoRateMultiplication):", price);
        console.log("Expected Price:", expectedPrice);
        assertEq(price, expectedPrice, "V2 price should not multiply by rate");

        // Verify rate is still returned correctly
        uint256 rate = oracle.getRate();
        console.log("Rate:", rate);
        assertEq(rate, fxsaveRate, "Rate should still be correct");
    }

    function test_InvertedPrice() public {
        // Test inverted price conversion
        // Normal: firstFeedPrice / secondFeedPrice (e.g., USDC/USD / BTC/USD = USDC/BTC)
        // Inverted: secondFeedPrice / firstFeedPrice (e.g., BTC/USD / USDC/USD = BTC/USDC)

        // Set first feed to USDC/USD for this test
        mockFirstFeed.setAnswer(usdcUsdPrice, block.timestamp);

        HarborDoubleFeedAndRateAggregator_v2 implementation = new HarborDoubleFeedAndRateAggregator_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborDoubleFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "TestOracle",
            1, // FXSAVE
            address(mockFirstFeed),
            address(mockSecondFeed),
            1, // priceDivisor
            maxAge,
            maxDev,
            maxAge,
            maxDev,
            true // invertPrice = true
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborDoubleFeedAndRateAggregator_v2(address(proxy));

        uint256 price = oracle.getPrice();

        // The contract normalizes prices internally, so we need to use the same normalization
        // First feed: USDC/USD = 1.0 (8 decimals) -> normalized to 18 decimals = 1e18
        // Second feed: BTC/USD = 100000.0 (8 decimals) -> normalized to 18 decimals = 1e23
        // Inverted: (secondFeedPrice * 1e18) / (firstFeedPrice * priceDivisor)
        // = (1e23 * 1e18) / (1e18 * 1) = 1e41 / 1e18 = 1e23
        // But wait, the actual result is 2.5e19, which suggests the feeds might have different values
        uint256 normalizedFirstPrice = uint256(usdcUsdPrice) * 1e10; // 1e8 * 1e10 = 1e18
        uint256 normalizedSecondPrice = uint256(btcUsdPrice) * 1e10; // 1e13 * 1e10 = 1e23
        // Inverted: (secondFeedPrice * 1e18) / (firstFeedPrice * priceDivisor)
        uint256 expectedPrice = Math.mulDiv(
            normalizedSecondPrice,
            1e18,
            Math.mulDiv(normalizedFirstPrice, 1, 1) // priceDivisor = 1
        );

        console.log("Price (Inverted):", price);
        console.log("Expected Price (Inverted):", expectedPrice);
        console.log("First Feed Price (USDC/USD, raw):", uint256(usdcUsdPrice));
        console.log("Second Feed Price (BTC/USD, raw):", uint256(btcUsdPrice));
        console.log("First Feed Price (normalized):", normalizedFirstPrice);
        console.log("Second Feed Price (normalized):", normalizedSecondPrice);

        // The actual calculation in the contract uses the normalized prices directly
        // Let's verify by checking what the contract actually receives
        assertEq(price, expectedPrice, "Inverted price should be secondFeedPrice / firstFeedPrice");
        assertTrue(oracle.invertPrice(), "invertPrice should be true");
    }

    function test_SetInvertPrice() public {
        HarborDoubleFeedAndRateAggregator_v2 implementation = new HarborDoubleFeedAndRateAggregator_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborDoubleFeedAndRateAggregator_v2.initialize.selector,
            owner,
            "TestOracle",
            1,
            address(mockFirstFeed),
            address(mockSecondFeed),
            1,
            maxAge,
            maxDev,
            maxAge,
            maxDev,
            false // invertPrice = false initially
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborDoubleFeedAndRateAggregator_v2(address(proxy));

        assertFalse(oracle.invertPrice(), "invertPrice should be false initially");

        // Get normal price
        uint256 normalPrice = oracle.getPrice();
        console.log("Price (Normal, before inversion):", normalPrice);

        // Set invertPrice to true
        oracle.setInvertPrice(true);
        assertTrue(oracle.invertPrice(), "invertPrice should be true after setting");

        // Get inverted price
        uint256 invertedPrice = oracle.getPrice();
        console.log("Price (Inverted, after setting):", invertedPrice);

        // Prices should be different (inverted)
        assertNotEq(normalPrice, invertedPrice, "Inverted price should differ from normal price");
    }
}
