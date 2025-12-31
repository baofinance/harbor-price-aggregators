// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {MockAggregatorV3} from "@harbor-test/mock/MockAggregatorV3.sol";
import {MockFxSAVE} from "@harbor-test/mock/MockFxSAVE.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";
import {IBaoFixedOwnable} from "@bao/interfaces/IBaoFixedOwnable.sol";
import {FxSaveRateLib} from "@harbor-price/rates/FxSaveRateLib.sol";
import {ChainlinkFeedLib} from "@harbor-price/feeds/chainlink/ChainlinkFeedLib.sol";

/// @title Base test contract for single-feed v3 aggregators (fxUSD pattern)
/// @notice Provides all tests; concrete contracts only implement factory + identity
abstract contract SingleFeedAggregatorTestBase is Test {
    MockFxSAVE mockFxSave;
    MockAggregatorV3 mockPriceFeed;

    IHarborPriceAggregatorV3 aggregator;

    uint256 constant DEFAULT_HEARTBEAT = 3600;
    uint256 constant VALID_FXSAVE_RATE = 1.05e18;

    /// @dev The fixed owner address from HarborAggregator_v3
    address constant OWNER = 0x9bABfC1A1952a6ed2caC1922BFfE80c0506364a2;

    /// @dev ERC1967 implementation slot
    bytes32 constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    // =========================================================================
    // Abstract: concrete tests implement these
    // =========================================================================

    /// @notice Returns the contract name (e.g., "Aggregator_fxUSD_BTC")
    function _contractName() internal pure virtual returns (string memory);

    /// @notice Deploy the aggregator with standard test parameters
    function _createAggregator(
        address fxsave,
        address priceFeed,
        uint256 heartbeat,
        uint256 divisor,
        bool invert
    ) internal virtual returns (IHarborPriceAggregatorV3);

    /// @notice Deploy with zero fxsave (for revert test)
    function _createWithZeroFxsave() internal virtual;

    /// @notice Deploy with zero price feed (for revert test)
    function _createWithZeroPriceFeed() internal virtual;

    /// @notice Deploy with zero divisor (for revert test)
    function _createWithZeroDivisor() internal virtual;

    // =========================================================================
    // String parsing helpers
    // =========================================================================

    /// @notice Parse "Aggregator_BASE_QUOTE" to extract BASE
    function _expectedBaseName() internal pure returns (string memory) {
        return _parseContractName(1);
    }

    /// @notice Parse "Aggregator_BASE_QUOTE" to extract QUOTE
    function _expectedQuoteName() internal pure returns (string memory) {
        return _parseContractName(2);
    }

    /// @notice Extract the Nth underscore-delimited part (0=Aggregator, 1=base, 2=quote)
    function _parseContractName(uint256 partIndex) internal pure returns (string memory) {
        bytes memory name = bytes(_contractName());
        uint256 start = 0;
        uint256 partCount = 0;

        for (uint256 i = 0; i <= name.length; i++) {
            if (i == name.length || name[i] == "_") {
                if (partCount == partIndex) {
                    bytes memory part = new bytes(i - start);
                    for (uint256 j = start; j < i; j++) {
                        part[j - start] = name[j];
                    }
                    return string(part);
                }
                partCount++;
                start = i + 1;
            }
        }
        revert("Part not found");
    }

    // =========================================================================
    // Setup
    // =========================================================================

    function setUp() public virtual {
        vm.warp(100_000);

        mockFxSave = new MockFxSAVE();
        mockPriceFeed = new MockAggregatorV3(8);

        mockFxSave.setAssetsPerShare(VALID_FXSAVE_RATE);
        mockPriceFeed.setAnswer(50000e8, block.timestamp);

        aggregator = _createAggregator(address(mockFxSave), address(mockPriceFeed), DEFAULT_HEARTBEAT, 1, true);
    }

    // =========================================================================
    // Constructor Validation
    // =========================================================================

    function test_constructor_revertsOnZeroFxsave() public {
        vm.expectRevert();
        _createWithZeroFxsave();
    }

    function test_constructor_revertsOnZeroPriceFeed() public {
        vm.expectRevert();
        _createWithZeroPriceFeed();
    }

    function test_constructor_revertsOnZeroDivisor() public {
        vm.expectRevert();
        _createWithZeroDivisor();
    }

    // =========================================================================
    // Interface Compliance
    // =========================================================================

    function test_baseName() public view {
        assertEq(aggregator.baseName(), _expectedBaseName());
    }

    function test_quoteName() public view {
        assertEq(aggregator.quoteName(), _expectedQuoteName());
    }

    function test_oracleName() public view {
        string memory expected = string.concat(_expectedBaseName(), "/", _expectedQuoteName());
        assertEq(aggregator.oracleName(), expected);
    }

    function test_version() public view {
        assertEq(aggregator.version(), 3);
    }

    function test_rateProvider() public view {
        assertEq(aggregator.rateProvider(), address(mockFxSave));
    }

    // =========================================================================
    // latestAnswer()
    // =========================================================================

    function test_latestAnswer_returnsValidTuple() public view {
        (uint256 p1, uint256 p2, uint256 r1, uint256 r2) = aggregator.latestAnswer();

        assertGt(p1, 0, "price1 > 0");
        assertEq(p1, p2, "price1 == price2");
        assertEq(r1, VALID_FXSAVE_RATE, "rate1");
        assertEq(r1, r2, "rate1 == rate2");
    }

    function test_latestAnswer_staleFeed_reverts() public {
        uint256 staleTime = block.timestamp - DEFAULT_HEARTBEAT - 43;
        mockPriceFeed.setAnswer(50000e8, staleTime);

        vm.expectRevert(
            abi.encodeWithSelector(
                ChainlinkFeedLib.StaleFeedData.selector,
                address(mockPriceFeed),
                staleTime,
                block.timestamp,
                DEFAULT_HEARTBEAT
            )
        );
        aggregator.latestAnswer();
    }

    function test_latestAnswer_invalidRate_reverts() public {
        uint256 lowRate = 0.8e18;
        mockFxSave.setAssetsPerShare(lowRate);

        vm.expectRevert(abi.encodeWithSelector(FxSaveRateLib.InvalidRate.selector, lowRate));
        aggregator.latestAnswer();
    }

    // =========================================================================
    // UUPS Upgrade
    // =========================================================================

    /// @notice Verifies upgrade authorization and observable behavior change
    /// @dev Uses different divisor values to produce different prices, proving the upgrade took effect
    function test_upgrade() public {
        // Deploy impl1 with divisor=1 (multiply mode)
        IHarborPriceAggregatorV3 impl1 = _createAggregator(
            address(mockFxSave),
            address(mockPriceFeed),
            DEFAULT_HEARTBEAT,
            1,
            true
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl1), "");
        IHarborPriceAggregatorV3 proxied = IHarborPriceAggregatorV3(address(proxy));

        // Capture price with impl1
        (uint256 price1, , , ) = proxied.latestAnswer();
        assertGt(price1, 0, "impl1 price should be positive");

        // Deploy impl2 with divisor=2 (halves the price)
        IHarborPriceAggregatorV3 impl2 = _createAggregator(
            address(mockFxSave),
            address(mockPriceFeed),
            DEFAULT_HEARTBEAT,
            2,
            true
        );

        // Non-owner cannot upgrade
        address notOwner = makeAddr("notOwner");
        vm.prank(notOwner);
        vm.expectRevert(IBaoFixedOwnable.Unauthorized.selector);
        UUPSUpgradeable(address(proxy)).upgradeToAndCall(address(impl2), "");

        // Owner can upgrade
        vm.prank(OWNER);
        UUPSUpgradeable(address(proxy)).upgradeToAndCall(address(impl2), "");

        // Verify behavior changed: price should differ due to different divisor
        (uint256 price2, , , ) = proxied.latestAnswer();
        assertNotEq(price2, price1, "Price should differ after upgrade to impl with different divisor");

        // Verify implementation slot changed
        address newImpl = address(uint160(uint256(vm.load(address(proxy), IMPLEMENTATION_SLOT))));
        assertEq(newImpl, address(impl2), "Implementation slot should point to impl2");
    }
}
