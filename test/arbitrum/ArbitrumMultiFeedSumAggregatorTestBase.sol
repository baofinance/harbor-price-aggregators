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

/// @title Base test contract for Arbitrum multi-feed v3 aggregators (MAG7 pattern: 7 feeds, rate feed, base USD feed)
/// @notice Provides all tests; concrete contracts only implement factory + identity
abstract contract ArbitrumMultiFeedSumAggregatorTestBase is Test {
    MockAggregatorV3 mockRateFeed;
    MockAggregatorV3 mockBaseUsdFeed;
    MockAggregatorV3[7] mockFeeds;

    IHarborPriceAggregatorV3 aggregator;

    uint256 constant DEFAULT_HEARTBEAT = 86400; // 24 hours
    uint256 constant VALID_RATE = 1.15e18; // 1.15 wstETH/stETH or sUSDE/USDE
    uint256 constant FEED_COUNT = 7;

    /// @dev The fixed owner address from HarborAggregator_v3
    address constant OWNER = 0x9bABfC1A1952a6ed2caC1922BFfE80c0506364a2;

    /// @dev ERC1967 implementation slot
    bytes32 constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    // =========================================================================
    // Abstract: concrete tests implement these
    // =========================================================================

    /// @notice Returns the contract name (e.g., "Aggregator_stETH_MAG7")
    function _contractName() internal pure virtual returns (string memory);

    /// @notice Deploy the aggregator with standard test parameters
    function _createAggregator(
        address rateFeed,
        address baseUsdFeed,
        uint256 baseUsdFeedHeartbeat,
        address[7] memory feeds,
        uint256[7] memory feedHeartbeats
    ) internal virtual returns (IHarborPriceAggregatorV3);

    /// @notice Deploy with zero rate feed (for revert test)
    function _createWithZeroRateFeed() internal virtual;

    /// @notice Deploy with zero base USD feed (for revert test)
    function _createWithZeroBaseUsdFeed() internal virtual;

    /// @notice Deploy with zero feed at index (for revert test)
    function _createWithZeroFeed(uint256 feedIndex) internal virtual;

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
        mockBaseUsdFeed = new MockAggregatorV3(8);

        // Create 7 mock feeds (all with 8 decimals like stock feeds)
        for (uint256 i = 0; i < FEED_COUNT; i++) {
            mockFeeds[i] = new MockAggregatorV3(8);
            // Set prices: 100e8, 150e8, 200e8, etc. (diverse test values)
            mockFeeds[i].setAnswer(int256((100 + i * 50) * 1e8), block.timestamp);
        }

        // Set rate feed (normalized to 18 decimals)
        mockRateFeed.setAnswer(int256(VALID_RATE), block.timestamp);
        // Set base USD feed (e.g., stETH/USD = 3000 USD)
        mockBaseUsdFeed.setAnswer(3000e8, block.timestamp);

        address[7] memory feedAddrs;
        uint256[7] memory feedHeartbeats_;
        for (uint256 i = 0; i < FEED_COUNT; i++) {
            feedAddrs[i] = address(mockFeeds[i]);
            feedHeartbeats_[i] = DEFAULT_HEARTBEAT;
        }

        aggregator = _createAggregator(
            address(mockRateFeed),
            address(mockBaseUsdFeed),
            DEFAULT_HEARTBEAT,
            feedAddrs,
            feedHeartbeats_
        );
    }

    // =========================================================================
    // Constructor Validation
    // =========================================================================

    function test_constructor_revertsOnZeroRateFeed() public {
        vm.expectRevert();
        _createWithZeroRateFeed();
    }

    function test_constructor_revertsOnZeroBaseUsdFeed() public {
        vm.expectRevert();
        _createWithZeroBaseUsdFeed();
    }

    function test_constructor_revertsOnZeroFeed0() public {
        vm.expectRevert();
        _createWithZeroFeed(0);
    }

    function test_constructor_revertsOnZeroFeed1() public {
        vm.expectRevert();
        _createWithZeroFeed(1);
    }

    function test_constructor_revertsOnZeroFeed2() public {
        vm.expectRevert();
        _createWithZeroFeed(2);
    }

    function test_constructor_revertsOnZeroFeed3() public {
        vm.expectRevert();
        _createWithZeroFeed(3);
    }

    function test_constructor_revertsOnZeroFeed4() public {
        vm.expectRevert();
        _createWithZeroFeed(4);
    }

    function test_constructor_revertsOnZeroFeed5() public {
        vm.expectRevert();
        _createWithZeroFeed(5);
    }

    function test_constructor_revertsOnZeroFeed6() public {
        vm.expectRevert();
        _createWithZeroFeed(6);
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
        (uint256 bidPrice, uint256 askPrice, uint256 bidRate, uint256 askRate) = aggregator.latestAnswer();

        console.log("=== Test Oracle ===");
        console.log("Base Name:", aggregator.baseName());
        console.log("Quote Name:", aggregator.quoteName());
        console.log("Oracle Name:", aggregator.oracleName());
        console.log("Bid Price (18 decimals):", bidPrice);
        console.log("Ask Price (18 decimals):", askPrice);
        console.log("Bid Rate (18 decimals):", bidRate);
        console.log("Ask Rate (18 decimals):", askRate);
        console.log("");

        assertGt(bidPrice, 0, "bidPrice > 0");
        assertEq(bidPrice, askPrice, "bidPrice == askPrice");
        assertEq(bidRate, VALID_RATE, "bidRate");
        assertEq(bidRate, askRate, "bidRate == askRate");
    }

    function test_latestAnswer_staleRateFeed_reverts() public {
        uint256 staleTime = block.timestamp - 86400 - 1; // 24 hours + 1 second
        mockRateFeed.setAnswer(int256(VALID_RATE), staleTime);

        vm.expectRevert(
            abi.encodeWithSelector(ChainlinkRateLib.StaleRateSource.selector, address(mockRateFeed), staleTime)
        );
        aggregator.latestAnswer();
    }

    function test_latestAnswer_staleBaseUsdFeed_reverts() public {
        uint256 staleTime = block.timestamp - DEFAULT_HEARTBEAT - 43;
        mockBaseUsdFeed.setAnswer(3000e8, staleTime);

        vm.expectRevert(
            abi.encodeWithSelector(
                ChainlinkFeedLib.StaleFeedData.selector,
                address(mockBaseUsdFeed),
                staleTime,
                block.timestamp,
                DEFAULT_HEARTBEAT
            )
        );
        aggregator.latestAnswer();
    }

    function test_latestAnswer_staleFeed0_reverts() public {
        uint256 staleTime = block.timestamp - DEFAULT_HEARTBEAT - 43;
        mockFeeds[0].setAnswer(100e8, staleTime);

        vm.expectRevert(
            abi.encodeWithSelector(
                ChainlinkFeedLib.StaleFeedData.selector,
                address(mockFeeds[0]),
                staleTime,
                block.timestamp,
                DEFAULT_HEARTBEAT
            )
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
    function test_upgrade() public {
        address[7] memory feedAddrs;
        uint256[7] memory feedHeartbeats_;
        for (uint256 i = 0; i < FEED_COUNT; i++) {
            feedAddrs[i] = address(mockFeeds[i]);
            feedHeartbeats_[i] = DEFAULT_HEARTBEAT;
        }

        // Deploy impl1
        IHarborPriceAggregatorV3 impl1 = _createAggregator(
            address(mockRateFeed),
            address(mockBaseUsdFeed),
            DEFAULT_HEARTBEAT,
            feedAddrs,
            feedHeartbeats_
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl1), "");
        IHarborPriceAggregatorV3 proxied = IHarborPriceAggregatorV3(address(proxy));

        // Capture price with impl1
        (uint256 price1, , , ) = proxied.latestAnswer();
        assertGt(price1, 0, "impl1 price should be positive");

        // Deploy impl2 (same constructor, but different instance)
        IHarborPriceAggregatorV3 impl2 = _createAggregator(
            address(mockRateFeed),
            address(mockBaseUsdFeed),
            DEFAULT_HEARTBEAT,
            feedAddrs,
            feedHeartbeats_
        );

        // Non-owner cannot upgrade
        address notOwner = makeAddr("notOwner");
        vm.prank(notOwner);
        vm.expectRevert(IBaoFixedOwnable.Unauthorized.selector);
        UUPSUpgradeable(address(proxy)).upgradeToAndCall(address(impl2), "");

        // Owner can upgrade
        vm.prank(OWNER);
        UUPSUpgradeable(address(proxy)).upgradeToAndCall(address(impl2), "");

        // Verify implementation slot changed
        address newImpl = address(uint160(uint256(vm.load(address(proxy), IMPLEMENTATION_SLOT))));
        assertEq(newImpl, address(impl2), "Implementation slot should point to impl2");

        // Price should be same (same parameters)
        (uint256 price2, , , ) = proxied.latestAnswer();
        assertEq(price2, price1, "Price should be same after upgrade (same parameters)");
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
