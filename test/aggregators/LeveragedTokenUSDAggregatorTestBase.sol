// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {MockAggregatorV3} from "@harbor-price-test/mock/MockAggregatorV3.sol";
import {MockMinter} from "@harbor-price-test/mock/MockMinter.sol";
import {MockFxSAVE} from "@harbor-price-test/mock/MockFxSAVE.sol";
import {MockWstETH} from "@harbor-price-test/mock/MockWstETH.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";
import {IBaoFixedOwnable} from "@bao/interfaces/IBaoFixedOwnable.sol";
import {ChainlinkFeedLib} from "@harbor-price/feeds/chainlink/ChainlinkFeedLib.sol";

/// @title Base test contract for leveraged token/USD v3 aggregators
/// @notice Provides all tests; concrete contracts only implement factory + identity
abstract contract LeveragedTokenUSDAggregatorTestBase is Test {
    MockMinter mockMinter;
    MockFxSAVE mockFxSAVE;
    MockWstETH mockWstETH;
    MockAggregatorV3 mockUnderlyingUsdFeed;

    IHarborPriceAggregatorV3 aggregator;

    uint256 constant DEFAULT_HEARTBEAT = 3600;
    uint256 constant VALID_LEVERAGED_TOKEN_PRICE = 1.2e18; // leveragedToken / underlying
    uint256 constant VALID_FXSAVE_RATE = 1.05e18;
    uint256 constant VALID_WSTETH_RATE = 1.15e18;

    /// @dev The fixed owner address from HarborAggregator_v3
    address constant OWNER = 0x9bABfC1A1952a6ed2caC1922BFfE80c0506364a2;

    /// @dev ERC1967 implementation slot
    bytes32 constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    // =========================================================================
    // Abstract: concrete tests implement these
    // =========================================================================

    /// @notice Returns the contract name (e.g., "Aggregator_hsfxUSD_EUR_USD")
    function _contractName() internal pure virtual returns (string memory);

    /// @notice Returns the expected base name (e.g., "hsfxUSD-EUR")
    function _expectedBaseName() internal pure virtual returns (string memory);

    /// @notice Deploy the aggregator with standard test parameters
    function _createAggregator(
        address minter,
        uint8 underlyingType,
        address underlying,
        address underlyingUsdFeed,
        uint256 underlyingUsdHeartbeat,
        string memory baseName
    ) internal virtual returns (IHarborPriceAggregatorV3);

    /// @notice Deploy with zero minter (for revert test)
    function _createWithZeroMinter() internal virtual;

    /// @notice Deploy with zero underlying (for revert test)
    function _createWithZeroUnderlying() internal virtual;

    /// @notice Deploy with zero underlying USD feed for stETH (for revert test)
    function _createWithZeroUnderlyingUsdFeed() internal virtual;

    // =========================================================================
    // Setup
    // =========================================================================

    function setUp() public virtual {
        vm.warp(100_000);

        mockMinter = new MockMinter();
        mockFxSAVE = new MockFxSAVE();
        mockWstETH = new MockWstETH();
        mockUnderlyingUsdFeed = new MockAggregatorV3(8);

        mockMinter.setLeveragedTokenPrice(VALID_LEVERAGED_TOKEN_PRICE);
        mockFxSAVE.setAssetsPerShare(VALID_FXSAVE_RATE);
        mockWstETH.setStEthPerToken(VALID_WSTETH_RATE);
        mockUnderlyingUsdFeed.setAnswer(3000e8, block.timestamp); // stETH/USD = 3000

        // Default setup for fxSAVE underlying (type 0)
        aggregator = _createAggregator(address(mockMinter), 0, address(mockFxSAVE), address(0), 0, _expectedBaseName());
    }

    // =========================================================================
    // Constructor Validation
    // =========================================================================

    function test_constructor_revertsOnZeroMinter() public {
        vm.expectRevert();
        _createWithZeroMinter();
    }

    function test_constructor_revertsOnZeroUnderlying() public {
        vm.expectRevert();
        _createWithZeroUnderlying();
    }

    // =========================================================================
    // Interface Compliance
    // =========================================================================

    function test_baseName() public view {
        assertEq(aggregator.baseName(), _expectedBaseName());
    }

    function test_quoteName() public view {
        assertEq(aggregator.quoteName(), "USD");
    }

    function test_oracleName() public view {
        string memory expected = string.concat(_expectedBaseName(), "/USD");
        assertEq(aggregator.oracleName(), expected);
    }

    function test_version() public view {
        assertEq(aggregator.version(), 3);
    }

    function test_rateProvider() public view {
        assertEq(aggregator.rateProvider(), address(mockMinter));
    }

    // =========================================================================
    // latestAnswer()
    // =========================================================================

    function test_latestAnswer_returnsValidTuple() public view {
        (uint256 p1, uint256 p2, uint256 r1, uint256 r2) = aggregator.latestAnswer();

        assertGt(p1, 0, "price1 > 0");
        assertEq(p1, p2, "price1 == price2");
        assertEq(r1, VALID_LEVERAGED_TOKEN_PRICE, "rate1");
        assertEq(r1, r2, "rate1 == rate2");
    }

    // =========================================================================
    // UUPS Upgrade
    // =========================================================================

    function test_upgrade() public {
        // Deploy impl1
        IHarborPriceAggregatorV3 impl1 = _createAggregator(
            address(mockMinter),
            0,
            address(mockFxSAVE),
            address(0),
            0,
            _expectedBaseName()
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl1), "");
        IHarborPriceAggregatorV3 proxied = IHarborPriceAggregatorV3(address(proxy));

        // Capture price with impl1
        (uint256 price1, , , ) = proxied.latestAnswer();
        assertGt(price1, 0, "impl1 price should be positive");

        // Deploy impl2 with different leveraged token price
        mockMinter.setLeveragedTokenPrice(1.5e18);
        IHarborPriceAggregatorV3 impl2 = _createAggregator(
            address(mockMinter),
            0,
            address(mockFxSAVE),
            address(0),
            0,
            _expectedBaseName()
        );

        // Non-owner cannot upgrade
        address notOwner = makeAddr("notOwner");
        vm.prank(notOwner);
        vm.expectRevert(IBaoFixedOwnable.Unauthorized.selector);
        UUPSUpgradeable(address(proxy)).upgradeToAndCall(address(impl2), "");

        // Owner can upgrade
        vm.prank(OWNER);
        UUPSUpgradeable(address(proxy)).upgradeToAndCall(address(impl2), "");

        // Verify behavior changed: price should differ due to different leveraged token price
        (uint256 price2, , , ) = proxied.latestAnswer();
        assertNotEq(price2, price1, "Price should differ after upgrade");

        // Verify implementation slot changed
        address newImpl = address(uint160(uint256(vm.load(address(proxy), IMPLEMENTATION_SLOT))));
        assertEq(newImpl, address(impl2), "Implementation slot should point to impl2");
    }
}
