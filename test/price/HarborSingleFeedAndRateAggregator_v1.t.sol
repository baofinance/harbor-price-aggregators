// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {HarborSingleFeedAndRateAggregator_v1} from "@harbor-price/price/HarborSingleFeedAndRateAggregator_v1.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {MockWstETH} from "test/mock/MockWstETH.sol";
import {MockFxSAVE} from "test/mock/MockFxSAVE.sol";
import {MockAggregatorV3} from "test/mock/MockAggregatorV3.sol";

// V2 contract for upgrade testing - same as V1, used to verify upgrade works
contract HarborSingleFeedAndRateAggregator_v2 is HarborSingleFeedAndRateAggregator_v1 {
    constructor(address wsteth_, address fxsave_, address susdeUsdeFeed_, address wstethStethFeed_)
        HarborSingleFeedAndRateAggregator_v1(wsteth_, fxsave_, susdeUsdeFeed_, wstethStethFeed_)
    {}
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
        HarborSingleFeedAndRateAggregator_v1 implementation = new HarborSingleFeedAndRateAggregator_v1(
            address(mockWstEth),
            address(mockFxSave),
            address(0), // SUSDE_USDE_FEED not used in tests
            address(0) // WSTETH_STETH_FEED not used in tests
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
            address(0) // WSTETH_STETH_FEED not used in tests
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
            address(0) // WSTETH_STETH_FEED not used in tests
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
            address(0) // WSTETH_STETH_FEED not used in tests
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
            address(0) // WSTETH_STETH_FEED not used in tests
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
            address(0) // WSTETH_STETH_FEED not used in tests
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

        (,, uint256 minRate, uint256 maxRate) = oracle.latestAnswer();
        assertEq(minRate, rate, "Incorrect rate (fuzz)");
        assertEq(maxRate, rate, "Rate mismatch (fuzz)");
    }

    /*//////////////////////////////////////////////////////////////
                            UPGRADE TESTS
    //////////////////////////////////////////////////////////////*/

    function test_Upgrade_Success() public {
        // Deploy V1 implementation and proxy
        HarborSingleFeedAndRateAggregator_v1 implementationV1 =
            new HarborSingleFeedAndRateAggregator_v1(address(mockWstEth), address(mockFxSave), address(0), address(0));

        bytes memory initData = abi.encodeWithSelector(
            HarborSingleFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            0,
            address(mockEthUsdFeed),
            1,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementationV1), initData);
        oracle = HarborSingleFeedAndRateAggregator_v1(address(proxy));

        // Store some state before upgrade
        string memory oracleNameBefore = oracle.oracleName();
        address ownerBefore = oracle.owner();
        uint256 priceBefore = oracle.getPrice();

        // Get V1 implementation address
        bytes32 implSlot = vm.load(address(proxy), IMPLEMENTATION_SLOT);
        address implV1 = address(uint160(uint256(implSlot)));
        assertEq(implV1, address(implementationV1), "V1 implementation should be set");

        // Deploy V2 implementation
        HarborSingleFeedAndRateAggregator_v2 implementationV2 =
            new HarborSingleFeedAndRateAggregator_v2(address(mockWstEth), address(mockFxSave), address(0), address(0));

        // Upgrade to V2
        vm.expectEmit(true, false, false, false);
        emit HarborSingleFeedAndRateAggregator_v1.Upgraded(address(implementationV2));

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
        HarborSingleFeedAndRateAggregator_v1 implementationV1 =
            new HarborSingleFeedAndRateAggregator_v1(address(mockWstEth), address(mockFxSave), address(0), address(0));

        bytes memory initData = abi.encodeWithSelector(
            HarborSingleFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            0,
            address(mockEthUsdFeed),
            1,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementationV1), initData);
        oracle = HarborSingleFeedAndRateAggregator_v1(address(proxy));

        // Deploy V2 implementation
        HarborSingleFeedAndRateAggregator_v2 implementationV2 =
            new HarborSingleFeedAndRateAggregator_v2(address(mockWstEth), address(mockFxSave), address(0), address(0));

        // Try to upgrade as non-owner
        address nonOwner = address(0x1234);
        vm.prank(nonOwner);
        vm.expectRevert(); // Should revert due to onlyOwner modifier
        oracle.upgradeToAndCall(address(implementationV2), "");
    }

    function test_Upgrade_PreservesState() public {
        // Deploy V1 implementation and proxy
        HarborSingleFeedAndRateAggregator_v1 implementationV1 =
            new HarborSingleFeedAndRateAggregator_v1(address(mockWstEth), address(mockFxSave), address(0), address(0));

        bytes memory initData = abi.encodeWithSelector(
            HarborSingleFeedAndRateAggregator_v1.initialize.selector,
            owner,
            "TestOracle",
            0,
            address(mockEthUsdFeed),
            1,
            maxAge,
            maxDev
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementationV1), initData);
        oracle = HarborSingleFeedAndRateAggregator_v1(address(proxy));

        // Update some state before upgrade
        uint64 newMaxAge = 7200;
        uint256 newMaxDev = 10e16;
        vm.prank(owner);
        oracle.setFeedConstraints(1, newMaxAge, newMaxDev);

        // Store state values
        string memory oracleNameBefore = oracle.oracleName();
        address ownerBefore = oracle.owner();
        address firstFeedBefore = oracle.firstFeed();
        uint8 firstFeedDecimalsBefore = oracle.firstFeedDecimals();
        uint256 priceDivisorBefore = oracle.priceDivisor();
        (uint64 maxAgeBefore, uint256 maxDevBefore) = oracle.getConstraints(1);

        // Deploy V2 implementation
        HarborSingleFeedAndRateAggregator_v2 implementationV2 =
            new HarborSingleFeedAndRateAggregator_v2(address(mockWstEth), address(mockFxSave), address(0), address(0));

        // Upgrade to V2
        vm.prank(owner);
        oracle.upgradeToAndCall(address(implementationV2), "");

        // Verify all state is preserved
        assertEq(oracle.oracleName(), oracleNameBefore, "Oracle name should be preserved");
        assertEq(oracle.owner(), ownerBefore, "Owner should be preserved");
        assertEq(oracle.firstFeed(), firstFeedBefore, "First feed should be preserved");
        assertEq(oracle.firstFeedDecimals(), firstFeedDecimalsBefore, "First feed decimals should be preserved");
        assertEq(oracle.priceDivisor(), priceDivisorBefore, "Price divisor should be preserved");
        (uint64 maxAgeAfter, uint256 maxDevAfter) = oracle.getConstraints(1);
        assertEq(maxAgeAfter, maxAgeBefore, "Max age should be preserved");
        assertEq(maxDevAfter, maxDevBefore, "Max dev should be preserved");
    }
}
