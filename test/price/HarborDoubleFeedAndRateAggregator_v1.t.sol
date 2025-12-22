// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {HarborDoubleFeedAndRateAggregator_v1} from "@harbor-price/price/HarborDoubleFeedAndRateAggregator_v1.sol";
import {IFxSAVE} from "@harbor-price/interfaces/IFxSAVE.sol";
import {IWstETH} from "@bao/interfaces/IWstETH.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

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

// V2 contract for upgrade testing - same as V1, used to verify upgrade works
contract HarborDoubleFeedAndRateAggregator_v2 is HarborDoubleFeedAndRateAggregator_v1 {
    constructor(
        address wsteth_,
        address fxsave_,
        address susdeUsdeFeed_,
        address wstethStethFeed_
    ) HarborDoubleFeedAndRateAggregator_v1(wsteth_, fxsave_, susdeUsdeFeed_, wstethStethFeed_) {}
}

contract HarborDoubleFeedAndRateAggregator_v1Test is Test {
    HarborDoubleFeedAndRateAggregator_v1 oracle;
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
        HarborDoubleFeedAndRateAggregator_v1 implementation = new HarborDoubleFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0) // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborDoubleFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "WstETHToBTC",
            HarborDoubleFeedAndRateAggregator_v1.RateSource.WSTETH,
            address(mockFirstFeed), // ETH/USD
            address(mockSecondFeed), // BTC/USD
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborDoubleFeedAndRateAggregator_v1(address(proxy));

        assertEq(oracle.owner(), owner, "Incorrect owner");
        // Oracle name is correctly set and accessible via oracleName()
        assertTrue(bytes(oracle.oracleName()).length > 0, "Oracle name should not be empty");
    }

    function test_FxSAVE_ToBTC_Deployment() public {
        // Deploy fxSAVE to BTC oracle (RateSource = 1 for fxSAVE, USDC/USD + BTC/USD)
        mockFirstFeed.setAnswer(usdcUsdPrice, block.timestamp);

        HarborDoubleFeedAndRateAggregator_v1 implementation = new HarborDoubleFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0) // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborDoubleFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            1,
            address(mockFirstFeed),
            address(mockSecondFeed),
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborDoubleFeedAndRateAggregator_v1(address(proxy));

        vm.prank(owner);
        assertEq(oracle.owner(), owner, "Incorrect owner");
        // Oracle name is correctly set and accessible via oracleName()
        assertTrue(bytes(oracle.oracleName()).length > 0, "Oracle name should not be empty");
    }

    // NOTE: MCAP oracle now uses HarborMCAPFeedAndRateAggregator_v1 instead
    // This test is removed as the double feed aggregator no longer handles MCAP divisors
    // See HarborMCAPFeedAndRateAggregator_v1.t.sol for MCAP-specific tests

    function test_GetPrice() public {
        HarborDoubleFeedAndRateAggregator_v1 implementation = new HarborDoubleFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0) // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborDoubleFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            1,
            address(mockFirstFeed),
            address(mockSecondFeed),
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborDoubleFeedAndRateAggregator_v1(address(proxy));

        vm.prank(owner);
        uint256 price = oracle.getPrice();
        assertTrue(price > 0, "Price should be positive");
    }

    function test_LatestAnswer() public {
        HarborDoubleFeedAndRateAggregator_v1 implementation = new HarborDoubleFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0) // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborDoubleFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            1,
            address(mockFirstFeed),
            address(mockSecondFeed),
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborDoubleFeedAndRateAggregator_v1(address(proxy));

        vm.prank(owner);
        (uint256 minPrice, uint256 maxPrice, uint256 minRate, uint256 maxRate) = oracle.latestAnswer();

        assertEq(minPrice, maxPrice, "Min/max price mismatch");
        assertEq(minRate, maxRate, "Min/max rate mismatch");
        assertEq(minRate, fxsaveRate, "Incorrect rate");
        assertTrue(minPrice > 0, "Price should be positive");
    }

    function test_UpdateBothConstraints() public {
        HarborDoubleFeedAndRateAggregator_v1 implementation = new HarborDoubleFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0) // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborDoubleFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            1,
            address(mockFirstFeed),
            address(mockSecondFeed),
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborDoubleFeedAndRateAggregator_v1(address(proxy));

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

        HarborDoubleFeedAndRateAggregator_v1 implementation = new HarborDoubleFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0) // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborDoubleFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            1,
            address(mockFirstFeed),
            address(mockSecondFeed),
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborDoubleFeedAndRateAggregator_v1(address(proxy));

        vm.prank(owner);
        (uint256 minPrice, , uint256 minRate, ) = oracle.latestAnswer();

        assertEq(minRate, rate, "Incorrect rate (fuzz)");
        assertTrue(minPrice > 0, "Price should be positive (fuzz)");
    }

    /*//////////////////////////////////////////////////////////////
                            MCAP TESTS
    //////////////////////////////////////////////////////////////*/

    function test_WstETH_ToMCAP_WithDivisor() public {
        // Set ETH/USD price
        mockFirstFeed.setAnswer(ethUsdPrice, block.timestamp);

        // Set MCAP/USD price (4T = 4000000000000000000000000000000 in 8 decimals)
        int256 mcapUsdPrice = 4000000000000000000000000; // 4T in 18 decimals
        mockSecondFeed.setAnswer(mcapUsdPrice, block.timestamp);

        // Deploy wstETH to MCAP with divisor=1e12
        HarborDoubleFeedAndRateAggregator_v1 implementation = new HarborDoubleFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0) // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborDoubleFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "WstETHToMCAP",
            0, // WSTETH
            address(mockFirstFeed),
            address(mockSecondFeed),
            1e12, // MCAP divisor
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborDoubleFeedAndRateAggregator_v1(address(proxy));

        vm.prank(owner);
        uint256 price = oracle.getPrice();

        // Expected: wstEthRate * ethUsdPrice * 1e12 / mcapUsdPrice
        // casting to 'uint256' is safe because price values are positive
        uint256 expectedPrice = (wstEthRate * uint256(ethUsdPrice) * 1e12) / uint256(mcapUsdPrice);
        assertEq(price, expectedPrice, "Incorrect MCAP price");
        assertTrue(price > 0, "Price should be positive");
    }

    function test_FxSAVE_ToMCAP_WithDivisor() public {
        // Set USDC/USD price
        mockFirstFeed.setAnswer(usdcUsdPrice, block.timestamp);

        // Set MCAP/USD price (4T)
        int256 mcapUsdPrice = 4000000000000000000000000; // 4T in 18 decimals
        mockSecondFeed.setAnswer(mcapUsdPrice, block.timestamp);

        // Deploy fxSAVE to MCAP with divisor=1e12
        HarborDoubleFeedAndRateAggregator_v1 implementation = new HarborDoubleFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0) // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborDoubleFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "FxSAVEToMCAP",
            1, // FXSAVE
            address(mockFirstFeed),
            address(mockSecondFeed),
            1e12, // MCAP divisor
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborDoubleFeedAndRateAggregator_v1(address(proxy));

        vm.prank(owner);
        uint256 price = oracle.getPrice();

        // Expected: fxsaveRate * usdcUsdPrice * 1e12 / mcapUsdPrice
        // casting to 'uint256' is safe because price values are positive
        uint256 expectedPrice = (fxsaveRate * uint256(usdcUsdPrice) * 1e12) / uint256(mcapUsdPrice);
        assertEq(price, expectedPrice, "Incorrect MCAP price");
        assertTrue(price > 0, "Price should be positive");
    }

    function test_Fuzz_WstETH_ToMCAP(uint256 fuzzWstEthRate, uint256 fuzzMcapPrice) public {
        // Constrain fuzz inputs
        fuzzWstEthRate = bound(fuzzWstEthRate, 1e18, 1.2e18); // wstETH rate typically 1.0-1.2
        fuzzMcapPrice = bound(fuzzMcapPrice, 1000000000000000000000000, 10000000000000000000000000); // MCAP 1T-10T (in 18 decimals)

        mockWstEth.setStEthPerToken(fuzzWstEthRate);
        mockFirstFeed.setAnswer(ethUsdPrice, block.timestamp);
        // casting to 'int256' is safe because fuzzMcapPrice is bounded to reasonable values
        mockSecondFeed.setAnswer(int256(fuzzMcapPrice), block.timestamp);

        HarborDoubleFeedAndRateAggregator_v1 implementation = new HarborDoubleFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0) // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborDoubleFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "WstETHToMCAP",
            0,
            address(mockFirstFeed),
            address(mockSecondFeed),
            1e12, // MCAP divisor
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborDoubleFeedAndRateAggregator_v1(address(proxy));

        vm.prank(owner);
        (uint256 minPrice, , uint256 minRate, ) = oracle.latestAnswer();

        assertEq(minRate, fuzzWstEthRate, "Incorrect wstETH rate (fuzz)");
        assertTrue(minPrice > 0, "MCAP price should be positive (fuzz)");
    }

    function test_Fuzz_FxSAVE_ToMCAP(uint256 fxSaveRate, uint256 mcapPrice) public {
        // Constrain fuzz inputs
        fxSaveRate = bound(fxSaveRate, 1e18, 1.5e18); // fxSAVE rate typically 1.0-1.5
        mcapPrice = bound(mcapPrice, 1000000000000000000000000, 10000000000000000000000000); // MCAP 1T-10T (in 18 decimals)

        mockFxSave.setAssetsPerShare(fxSaveRate);
        mockFirstFeed.setAnswer(usdcUsdPrice, block.timestamp);
        // casting to 'int256' is safe because mcapPrice is bounded to reasonable values
        mockSecondFeed.setAnswer(int256(mcapPrice), block.timestamp);

        HarborDoubleFeedAndRateAggregator_v1 implementation = new HarborDoubleFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0) // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborDoubleFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "FxSAVEToMCAP",
            1,
            address(mockFirstFeed),
            address(mockSecondFeed),
            1e12, // MCAP divisor
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborDoubleFeedAndRateAggregator_v1(address(proxy));

        vm.prank(owner);
        (uint256 minPrice, , uint256 minRate, ) = oracle.latestAnswer();

        assertEq(minRate, fxSaveRate, "Incorrect fxSAVE rate (fuzz)");
        assertTrue(minPrice > 0, "MCAP price should be positive (fuzz)");
    }

    /*//////////////////////////////////////////////////////////////
                            UPGRADE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Upgrade_Success() public {
        // Deploy V1 implementation and proxy
        HarborDoubleFeedAndRateAggregator_v1 implementationV1 = new HarborDoubleFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborDoubleFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            1,
            address(mockFirstFeed),
            address(mockSecondFeed),
            1, // priceDivisor
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementationV1), initData);
        oracle = HarborDoubleFeedAndRateAggregator_v1(address(proxy));

        // Store some state before upgrade
        string memory oracleNameBefore = oracle.oracleName();
        address ownerBefore = oracle.owner();
        uint256 priceBefore = oracle.getPrice();

        // Get V1 implementation address
        bytes32 implSlot = vm.load(address(proxy), IMPLEMENTATION_SLOT);
        address implV1 = address(uint160(uint256(implSlot)));
        assertEq(implV1, address(implementationV1), "V1 implementation should be set");

        // Deploy V2 implementation
        HarborDoubleFeedAndRateAggregator_v2 implementationV2 = new HarborDoubleFeedAndRateAggregator_v2(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        // Upgrade to V2
        vm.expectEmit(true, false, false, false);
        emit HarborDoubleFeedAndRateAggregator_v1.Upgraded(address(implementationV2));

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

        // Verify functionality still works
        uint256 priceAfter = oracle.getPrice();
        assertEq(priceAfter, priceBefore, "Price should be unchanged after upgrade");
    }

    function test_Upgrade_Revert_NonOwner() public {
        // Deploy V1 implementation and proxy
        HarborDoubleFeedAndRateAggregator_v1 implementationV1 = new HarborDoubleFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborDoubleFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            1,
            address(mockFirstFeed),
            address(mockSecondFeed),
            1, // priceDivisor
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementationV1), initData);
        oracle = HarborDoubleFeedAndRateAggregator_v1(address(proxy));

        // Deploy V2 implementation
        HarborDoubleFeedAndRateAggregator_v2 implementationV2 = new HarborDoubleFeedAndRateAggregator_v2(
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
        HarborDoubleFeedAndRateAggregator_v1 implementationV1 = new HarborDoubleFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0),
            address(0)
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborDoubleFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            1,
            address(mockFirstFeed),
            address(mockSecondFeed),
            1, // priceDivisor
            maxAge,
            maxDev,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementationV1), initData);
        oracle = HarborDoubleFeedAndRateAggregator_v1(address(proxy));

        // Update some state before upgrade
        uint64 newMaxAge1 = 7200;
        uint256 newMaxDev1 = 10e16;
        uint64 newMaxAge2 = 14400;
        uint256 newMaxDev2 = 15e16;
        vm.prank(owner);
        oracle.updateBothConstraints(newMaxAge1, newMaxDev1, newMaxAge2, newMaxDev2);

        // Store state values
        string memory oracleNameBefore = oracle.oracleName();
        address ownerBefore = oracle.owner();
        address firstFeedBefore = oracle.firstFeed();
        address secondFeedBefore = oracle.secondFeed();
        uint8 firstFeedDecimalsBefore = oracle.firstFeedDecimals();
        uint8 secondFeedDecimalsBefore = oracle.secondFeedDecimals();
        uint256 priceDivisorBefore = oracle.priceDivisor();
        (uint64 maxAge1Before, uint256 maxDev1Before) = oracle.getConstraints(1);
        (uint64 maxAge2Before, uint256 maxDev2Before) = oracle.getConstraints(2);

        // Deploy V2 implementation
        HarborDoubleFeedAndRateAggregator_v2 implementationV2 = new HarborDoubleFeedAndRateAggregator_v2(
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
        assertEq(oracle.firstFeed(), firstFeedBefore, "First feed should be preserved");
        assertEq(oracle.secondFeed(), secondFeedBefore, "Second feed should be preserved");
        assertEq(oracle.firstFeedDecimals(), firstFeedDecimalsBefore, "First feed decimals should be preserved");
        assertEq(oracle.secondFeedDecimals(), secondFeedDecimalsBefore, "Second feed decimals should be preserved");
        assertEq(oracle.priceDivisor(), priceDivisorBefore, "Price divisor should be preserved");
        (uint64 maxAge1After, uint256 maxDev1After) = oracle.getConstraints(1);
        (uint64 maxAge2After, uint256 maxDev2After) = oracle.getConstraints(2);
        assertEq(maxAge1After, maxAge1Before, "First feed max age should be preserved");
        assertEq(maxDev1After, maxDev1Before, "First feed max dev should be preserved");
        assertEq(maxAge2After, maxAge2Before, "Second feed max age should be preserved");
        assertEq(maxDev2After, maxDev2Before, "Second feed max dev should be preserved");
    }
}
