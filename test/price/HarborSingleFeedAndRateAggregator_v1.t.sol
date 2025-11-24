// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {HarborSingleFeedAndRateAggregator_v1} from "src/price/HarborSingleFeedAndRateAggregator_v1.sol";
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

    function allowance(address, address) external pure override returns (uint256) { return 0; }
    function approve(address, uint256) external pure override returns (bool) { return true; }
    function balanceOf(address) external pure override returns (uint256) { return 0; }
    function totalSupply() external pure override returns (uint256) { return 0; }
    function transfer(address, uint256) external pure override returns (bool) { return true; }
    function transferFrom(address, address, uint256) external pure override returns (bool) { return true; }
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
    function asset() external pure override returns (address) { return address(0); }
    function convertToShares(uint256) external pure override returns (uint256) { return 0; }
    function deposit(uint256, address) external pure override returns (uint256) { return 0; }
    function maxDeposit(address) external pure override returns (uint256) { return 0; }
    function maxMint(address) external pure override returns (uint256) { return 0; }
    function maxRedeem(address) external pure override returns (uint256) { return 0; }
    function maxWithdraw(address) external pure override returns (uint256) { return 0; }
    function mint(uint256, address) external pure override returns (uint256) { return 0; }
    function previewDeposit(uint256) external pure override returns (uint256) { return 0; }
    function previewMint(uint256) external pure override returns (uint256) { return 0; }
    function previewRedeem(uint256) external pure override returns (uint256) { return 0; }
    function previewWithdraw(uint256) external pure override returns (uint256) { return 0; }
    function redeem(uint256, address, address) external pure override returns (uint256) { return 0; }
    function totalAssets() external pure override returns (uint256) { return 0; }
    function withdraw(uint256, address, address) external pure override returns (uint256) { return 0; }

    // IERC20Metadata stubs
    function name() external pure override returns (string memory) { return ""; }
    function symbol() external pure override returns (string memory) { return ""; }
    function decimals() external pure override returns (uint8) { return 18; }

    // IERC20 stubs
    function allowance(address, address) external pure override returns (uint256) { return 0; }
    function approve(address, uint256) external pure override returns (bool) { return true; }
    function balanceOf(address) external pure override returns (uint256) { return 0; }
    function totalSupply() external pure override returns (uint256) { return 0; }
    function transfer(address, uint256) external pure override returns (bool) { return true; }
    function transferFrom(address, address, uint256) external pure override returns (bool) { return true; }

    // IFxSAVE-specific stubs
    function CLAIM_FOR_ROLE() external pure override returns (bytes32) { return bytes32(0); }
    function DEFAULT_ADMIN_ROLE() external pure override returns (bytes32) { return bytes32(0); }
    function DOMAIN_SEPARATOR() external pure override returns (bytes32) { return bytes32(0); }
    function base() external pure override returns (address) { return address(0); }
    function gauge() external pure override returns (address) { return address(0); }
    function getExpenseRatio() external pure override returns (uint256) { return 0; }
    function getHarvesterRatio() external pure override returns (uint256) { return 0; }
    function getRoleAdmin(bytes32) external pure override returns (bytes32) { return bytes32(0); }
    function getThreshold() external pure override returns (uint256) { return 0; }
    function harvester() external pure override returns (address) { return address(0); }
    function hasRole(bytes32, address) external pure override returns (bool) { return false; }
    function lockedProxy(address) external pure override returns (address) { return address(0); }
    function nav() external pure override returns (uint256) { return 0; }
    function nonces(address) external pure override returns (uint256) { return 0; }
    function supportsInterface(bytes4) external pure override returns (bool) { return false; }
    function treasury() external pure override returns (address) { return address(0); }
    function vault() external pure override returns (address) { return address(0); }
    function eip712Domain() external pure override returns (bytes1, string memory, string memory, uint256, address, bytes32, uint256[] memory) { 
        return (bytes1(0), "", "", 0, address(0), bytes32(0), new uint256[](0)); 
    }
}

contract MockAggregatorV3 is AggregatorV3Interface {
    uint8 private _decimals;
    int256 private _answer;
    uint80 private _roundId;
    uint256 private _updatedAt;

    constructor(uint8 decimals_) { _decimals = decimals_; }

    function setAnswer(int256 answer_, uint256 updatedAt_) external {
        _answer = answer_;
        _updatedAt = updatedAt_;
        _roundId++;
    }

    function decimals() external view override returns (uint8) { return _decimals; }

    function latestRoundData() external view override returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        return (_roundId, _answer, 0, _updatedAt, _roundId);
    }

    function description() external pure override returns (string memory) { return ""; }
    function version() external pure override returns (uint256) { return 1; }
    function getRoundData(uint80) external view override returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) {
        return (_roundId, _answer, 0, _updatedAt, _roundId);
    }
}

contract HarborSingleFeedAndRateAggregator_v1Test is Test {
    HarborSingleFeedAndRateAggregator_v1 oracle;
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
        HarborSingleFeedAndRateAggregator_v1 implementation = new HarborSingleFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0)  // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborSingleFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "WstETHToETH",
            0,
            address(mockEthUsdFeed),
            1, // priceDivisor
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborSingleFeedAndRateAggregator_v1(address(proxy));

        assertEq(oracle.owner(), owner, "Incorrect owner");
        // Oracle name is correctly set and accessible via oracleName()
        assertTrue(bytes(oracle.oracleName()).length > 0, "Oracle name should not be empty");
    }

    function test_FxSAVE_Deployment() public {
        // Deploy fxSAVE oracle (RateSource = 1 for fxSAVE)
        HarborSingleFeedAndRateAggregator_v1 implementation = new HarborSingleFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0)  // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborSingleFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "FxSAVEToETH",
            1,
            address(mockEthUsdFeed),
            1, // priceDivisor
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborSingleFeedAndRateAggregator_v1(address(proxy));

        assertEq(oracle.owner(), owner, "Incorrect owner");
        // Oracle name is correctly set and accessible via oracleName()
        assertTrue(bytes(oracle.oracleName()).length > 0, "Oracle name should not be empty");
    }

    function test_WstETH_GetPrice() public {
        HarborSingleFeedAndRateAggregator_v1 implementation = new HarborSingleFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0)  // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborSingleFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            0,
            address(mockEthUsdFeed),
            1, // priceDivisor
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborSingleFeedAndRateAggregator_v1(address(proxy));

        // For wstETH single feed, price = (rate * firstFeedPrice) / 1e18 / priceDivisor
        // rate = wstEthRate (1.208... stETH/wstETH)
        // ethUsdPrice = 4000 USD/ETH (normalized to 18 decimals)
        // price = (rate * normalizedEthUsdPrice) / 1e18
        uint256 price = oracle.getPrice();
        // Expected: (rate * normalizedEthUsdPrice) / 1e18
        // normalizedEthUsdPrice = 400000000000 * 1e10 = 4000000000000000000000
        // casting to 'uint256' is safe because ethUsdPrice is a positive price value
        // forge-lint: disable-next-line unsafe-typecast
        uint256 normalizedEthUsdPrice = uint256(ethUsdPrice) * 1e10;
        uint256 expectedPrice = Math.mulDiv(wstEthRate, normalizedEthUsdPrice, 1e18);
        
        assertEq(price, expectedPrice, "Incorrect wstETH price");
    }

    function test_FxSAVE_LatestAnswer() public {
        uint256 fxsaveRate = 1052400000000000000; // 1.0524
        mockFxSave.setAssetsPerShare(fxsaveRate);

        HarborSingleFeedAndRateAggregator_v1 implementation = new HarborSingleFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0)  // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborSingleFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "FxSAVEToETH",
            1, // FXSAVE
            address(mockEthUsdFeed),
            1, // priceDivisor
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborSingleFeedAndRateAggregator_v1(address(proxy));

        (uint256 minPrice, uint256 maxPrice, uint256 minRate, uint256 maxRate) = oracle.latestAnswer();
        
        assertEq(minPrice, maxPrice, "Min/max price mismatch");
        assertEq(minRate, maxRate, "Min/max rate mismatch");
        assertEq(minRate, fxsaveRate, "Incorrect rate");
        assertTrue(minPrice > 0, "Price should be positive");
    }

    function test_UpdateConstraints() public {
        HarborSingleFeedAndRateAggregator_v1 implementation = new HarborSingleFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0)  // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborSingleFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            0,
            address(mockEthUsdFeed),
            1, // priceDivisor
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborSingleFeedAndRateAggregator_v1(address(proxy));

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

        HarborSingleFeedAndRateAggregator_v1 implementation = new HarborSingleFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0)  // WSTETH_STETH_FEED not used in tests
        );

        bytes memory initData = abi.encodeWithSelector(
            HarborSingleFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "FxSAVEToETH",
            1, // FXSAVE
            address(mockEthUsdFeed),
            1, // priceDivisor
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), initData);
        oracle = HarborSingleFeedAndRateAggregator_v1(address(proxy));

        (, , uint256 minRate, uint256 maxRate) = oracle.latestAnswer();
        assertEq(minRate, rate, "Incorrect rate (fuzz)");
        assertEq(maxRate, rate, "Rate mismatch (fuzz)");
    }
}

