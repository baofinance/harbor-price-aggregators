// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {MockAggregatorV3} from "@harbor-test/mock/MockAggregatorV3.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";
import {IBaoFixedOwnable} from "@bao/interfaces/IBaoFixedOwnable.sol";
import {ChainlinkFeedLib} from "@harbor-price/feeds/chainlink/ChainlinkFeedLib.sol";
import {ChainlinkRateLib} from "@harbor-price/rates/ChainlinkRateLib.sol";

/// @title Base test contract for Arbitrum double-feed v3 aggregators (stETH/USDE pattern with Chainlink rate feeds)
/// @notice Provides all tests; concrete contracts only implement factory + identity
abstract contract ArbitrumDoubleFeedAggregatorTestBase is Test {
    MockAggregatorV3 mockRateFeed;
    MockAggregatorV3 mockFirstFeed;
    MockAggregatorV3 mockSecondFeed;

    IHarborPriceAggregatorV3 aggregator;

    uint256 constant DEFAULT_HEARTBEAT = 3600;
    uint256 constant VALID_RATE = 1.15e18; // 1.15 wstETH/stETH or sUSDE/USDE

    /// @dev The fixed owner address from HarborAggregator_v3
    address constant OWNER = 0x9bABfC1A1952a6ed2caC1922BFfE80c0506364a2;

    /// @dev ERC1967 implementation slot
    bytes32 constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    // =========================================================================
    // Abstract: concrete tests implement these
    // =========================================================================

    /// @notice Returns the contract name (e.g., "Aggregator_stETH_AAPL")
    function _contractName() internal pure virtual returns (string memory);

    /// @notice Deploy the aggregator with standard test parameters
    function _createAggregator(
        address rateFeed,
        address firstFeed,
        uint256 firstHeartbeat,
        address secondFeed,
        uint256 secondHeartbeat,
        uint256 divisor,
        bool invert
    ) internal virtual returns (IHarborPriceAggregatorV3);

    /// @notice Deploy with zero rate feed (for revert test)
    function _createWithZeroRateFeed() internal virtual;

    /// @notice Deploy with zero first feed (for revert test)
    function _createWithZeroFirstFeed() internal virtual;

    /// @notice Deploy with zero second feed (for revert test)
    function _createWithZeroSecondFeed() internal virtual;

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

        mockRateFeed = new MockAggregatorV3(18);
        mockFirstFeed = new MockAggregatorV3(8);
        mockSecondFeed = new MockAggregatorV3(8);

        // Set rate feed (normalized to 18 decimals, so 1.15e18)
        mockRateFeed.setAnswer(int256(VALID_RATE), block.timestamp);
        mockFirstFeed.setAnswer(3000e8, block.timestamp);
        mockSecondFeed.setAnswer(200e8, block.timestamp);

        aggregator = _createAggregator(
            address(mockRateFeed),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    // =========================================================================
    // Constructor Validation
    // =========================================================================

    function test_constructor_revertsOnZeroRateFeed() public {
        vm.expectRevert();
        _createWithZeroRateFeed();
    }

    function test_constructor_revertsOnZeroFirstFeed() public {
        vm.expectRevert();
        _createWithZeroFirstFeed();
    }

    function test_constructor_revertsOnZeroSecondFeed() public {
        vm.expectRevert();
        _createWithZeroSecondFeed();
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
        assertEq(aggregator.rateProvider(), address(mockRateFeed));
    }

    // =========================================================================
    // latestAnswer()
    // =========================================================================

    function test_latestAnswer_returnsValidTuple() public view {
        (uint256 p1, uint256 p2, uint256 r1, uint256 r2) = aggregator.latestAnswer();

        assertGt(p1, 0, "price1 > 0");
        assertEq(p1, p2, "price1 == price2");
        assertEq(r1, VALID_RATE, "rate1");
        assertEq(r1, r2, "rate1 == rate2");

        // Console output for debugging
        console.log("Bid Price (18 decimals):", p1);
        console.log("Ask Price (18 decimals):", p2);
        console.log("Bid Rate (18 decimals):", r1);
        console.log("Ask Rate (18 decimals):", r2);
        console.log("");
    }

    function test_latestAnswer_staleFirstFeed_reverts() public {
        uint256 staleTime = block.timestamp - DEFAULT_HEARTBEAT - 43;
        mockFirstFeed.setAnswer(3000e8, staleTime);

        vm.expectRevert(
            abi.encodeWithSelector(
                ChainlinkFeedLib.StaleFeedData.selector,
                address(mockFirstFeed),
                staleTime,
                block.timestamp,
                DEFAULT_HEARTBEAT
            )
        );
        aggregator.latestAnswer();
    }

    function test_latestAnswer_staleSecondFeed_reverts() public {
        uint256 staleTime = block.timestamp - DEFAULT_HEARTBEAT - 43;
        mockSecondFeed.setAnswer(200e8, staleTime);

        vm.expectRevert(
            abi.encodeWithSelector(
                ChainlinkFeedLib.StaleFeedData.selector,
                address(mockSecondFeed),
                staleTime,
                block.timestamp,
                DEFAULT_HEARTBEAT
            )
        );
        aggregator.latestAnswer();
    }

    function test_latestAnswer_staleRateFeed_reverts() public {
        uint256 staleTime = block.timestamp - 86400 - 1; // 24 hours + 1 second
        mockRateFeed.setAnswer(int256(VALID_RATE), staleTime);

        vm.expectRevert(
            abi.encodeWithSelector(ChainlinkRateLib.StaleRateSource.selector, address(mockRateFeed), staleTime)
        );
        aggregator.latestAnswer();
    }

    function test_latestAnswer_rateBelowMin_reverts() public {
        uint256 lowRate = 0.9e18;
        mockRateFeed.setAnswer(int256(lowRate), block.timestamp);

        vm.expectRevert(abi.encodeWithSelector(ChainlinkRateLib.InvalidRate.selector, lowRate));
        aggregator.latestAnswer();
    }

    function test_latestAnswer_rateAboveMax_reverts() public {
        uint256 highRate = 2.1e18;
        mockRateFeed.setAnswer(int256(highRate), block.timestamp);

        vm.expectRevert(abi.encodeWithSelector(ChainlinkRateLib.InvalidRate.selector, highRate));
        aggregator.latestAnswer();
    }

    // =========================================================================
    // UUPS Upgrade
    // =========================================================================

    /// @notice Verifies upgrade authorization and observable behavior change
    /// @dev Uses different divisor values to produce different prices, proving the upgrade took effect
    function test_upgrade() public {
        // Deploy impl1 with divisor=1
        IHarborPriceAggregatorV3 impl1 = _createAggregator(
            address(mockRateFeed),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl1), "");
        IHarborPriceAggregatorV3 proxied = IHarborPriceAggregatorV3(address(proxy));

        // Capture price with impl1
        (uint256 price1, , , ) = proxied.latestAnswer();
        assertGt(price1, 0, "impl1 price should be positive");

        // Deploy impl2 with divisor=2 (halves the price)
        IHarborPriceAggregatorV3 impl2 = _createAggregator(
            address(mockRateFeed),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            2,
            false
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

    // =========================================================================
    // Console Output Helpers
    // =========================================================================

    function test_CheckOracleMetadata() public view {
        console.log("=== Oracle Metadata ===");
        console.log("Base:", aggregator.baseName());
        console.log("Rate Provider:", aggregator.rateProvider());
        console.log("Quote Name:", aggregator.quoteName());
        console.log("Oracle Name:", aggregator.oracleName());
        console.log("");
    }
}
