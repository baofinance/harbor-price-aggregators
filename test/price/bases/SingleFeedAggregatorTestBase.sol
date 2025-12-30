// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {MockAggregatorV3} from "@harbor-test/mock/MockAggregatorV3.sol";
import {MockFxSAVE} from "@harbor-test/mock/MockFxSAVE.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {FxSaveRateLib} from "@harbor-price/rates/FxSaveRateLib.sol";
import {ChainlinkFeedLib} from "@harbor-price/feeds/chainlink/ChainlinkFeedLib.sol";

/// @title Base test contract for single-feed v3 aggregators (fxUSD pattern)
/// @notice Inherit this and implement the abstract methods to test any single-feed aggregator
/// @dev Pattern: Template Method - subclasses provide factory and identity, base provides all tests
abstract contract SingleFeedAggregatorTestBase is Test {
    MockFxSAVE mockFxSave;
    MockAggregatorV3 mockPriceFeed;

    uint256 constant DEFAULT_HEARTBEAT = 3600;
    uint256 constant VALID_FXSAVE_RATE = 1.05e18;
    int256 constant DEFAULT_FEED_ANSWER = 50000e8;

    // =========================================================================
    // Abstract methods - subclasses must implement
    // =========================================================================

    /// @notice Deploy the aggregator with valid test parameters
    function createAggregator() internal virtual returns (IWrappedPriceOracle);

    /// @notice Expected base name (e.g., "fxUSD")
    function expectedBaseName() internal pure virtual returns (string memory);

    /// @notice Expected quote name (e.g., "BTC", "EUR", "XAU", "MCAP")
    function expectedQuoteName() internal pure virtual returns (string memory);

    /// @notice The error selector for InvalidAddress (may vary by contract)
    function invalidAddressSelector() internal pure virtual returns (bytes4);

    /// @notice The error selector for InvalidDivisor (may vary by contract)
    function invalidDivisorSelector() internal pure virtual returns (bytes4);

    /// @notice Deploy aggregator with zero fxsave (should revert)
    function createWithZeroFxSave() internal virtual;

    /// @notice Deploy aggregator with zero price feed (should revert)
    function createWithZeroPriceFeed() internal virtual;

    /// @notice Deploy aggregator with zero divisor (should revert)
    function createWithZeroDivisor() internal virtual;

    // =========================================================================
    // Setup
    // =========================================================================

    function setUp() public virtual {
        vm.warp(100_000); // Avoid timestamp underflow in staleness tests

        mockFxSave = new MockFxSAVE();
        mockPriceFeed = new MockAggregatorV3(8);

        mockFxSave.setAssetsPerShare(VALID_FXSAVE_RATE);
        mockPriceFeed.setAnswer(DEFAULT_FEED_ANSWER, block.timestamp);
    }

    // =========================================================================
    // Constructor Validation Tests
    // =========================================================================

    function test_constructor_revertsOnZeroFxsave() public {
        vm.expectRevert(abi.encodeWithSelector(invalidAddressSelector(), address(0)));
        createWithZeroFxSave();
    }

    function test_constructor_revertsOnZeroPriceFeed() public {
        vm.expectRevert(abi.encodeWithSelector(invalidAddressSelector(), address(0)));
        createWithZeroPriceFeed();
    }

    function test_constructor_revertsOnZeroDivisor() public {
        vm.expectRevert(abi.encodeWithSelector(invalidDivisorSelector(), 0));
        createWithZeroDivisor();
    }

    function test_constructor_acceptsValidArgs() public {
        IWrappedPriceOracle agg = createAggregator();
        assertTrue(address(agg) != address(0), "Should deploy successfully");
    }

    // =========================================================================
    // Interface Compliance Tests
    // =========================================================================

    function test_baseName() public {
        IWrappedPriceOracle agg = createAggregator();
        // Cast to get access to baseName - all our aggregators have this
        (bool success, bytes memory data) = address(agg).staticcall(abi.encodeWithSignature("baseName()"));
        assertTrue(success, "baseName() should exist");
        string memory baseName = abi.decode(data, (string));
        assertEq(baseName, expectedBaseName(), "baseName mismatch");
    }

    function test_quoteName() public {
        IWrappedPriceOracle agg = createAggregator();
        (bool success, bytes memory data) = address(agg).staticcall(abi.encodeWithSignature("quoteName()"));
        assertTrue(success, "quoteName() should exist");
        string memory quoteName = abi.decode(data, (string));
        assertEq(quoteName, expectedQuoteName(), "quoteName mismatch");
    }

    function test_oracleName() public {
        IWrappedPriceOracle agg = createAggregator();
        (bool success, bytes memory data) = address(agg).staticcall(abi.encodeWithSignature("oracleName()"));
        assertTrue(success, "oracleName() should exist");
        string memory oracleName = abi.decode(data, (string));
        assertEq(oracleName, string.concat(expectedBaseName(), "/", expectedQuoteName()), "oracleName mismatch");
    }

    function test_version() public {
        IWrappedPriceOracle agg = createAggregator();
        (bool success, bytes memory data) = address(agg).staticcall(abi.encodeWithSignature("version()"));
        assertTrue(success, "version() should exist");
        uint256 version = abi.decode(data, (uint256));
        assertEq(version, 3, "version should be 3");
    }

    function test_rateProvider() public {
        IWrappedPriceOracle agg = createAggregator();
        (bool success, bytes memory data) = address(agg).staticcall(abi.encodeWithSignature("rateProvider()"));
        assertTrue(success, "rateProvider() should exist");
        address rateProvider = abi.decode(data, (address));
        assertEq(rateProvider, address(mockFxSave), "rateProvider should be fxSAVE");
    }

    // =========================================================================
    // latestAnswer() Tests
    // =========================================================================

    function test_latestAnswer_returnsValidTuple() public {
        IWrappedPriceOracle agg = createAggregator();

        (uint256 p1, uint256 p2, uint256 r1, uint256 r2) = agg.latestAnswer();

        // Prices should be equal and non-zero
        assertEq(p1, p2, "prices should be equal");
        assertTrue(p1 > 0, "price should be non-zero");

        // Rates should be equal and match expected
        assertEq(r1, r2, "rates should be equal");
        assertEq(r1, VALID_FXSAVE_RATE, "rate should match fxSAVE rate");
    }

    function test_latestAnswer_staleFeed_reverts() public {
        IWrappedPriceOracle agg = createAggregator();

        // Make feed stale
        uint256 staleTime = block.timestamp - DEFAULT_HEARTBEAT - 43;
        mockPriceFeed.setAnswer(DEFAULT_FEED_ANSWER, staleTime);

        vm.expectRevert(
            abi.encodeWithSelector(
                ChainlinkFeedLib.StaleFeedData.selector,
                address(mockPriceFeed),
                staleTime,
                block.timestamp,
                DEFAULT_HEARTBEAT
            )
        );
        agg.latestAnswer();
    }

    function test_latestAnswer_invalidRate_reverts() public {
        IWrappedPriceOracle agg = createAggregator();

        // Set rate below minimum (0.9e18)
        uint256 lowRate = 0.8e18;
        mockFxSave.setAssetsPerShare(lowRate);

        vm.expectRevert(abi.encodeWithSelector(FxSaveRateLib.InvalidRate.selector, lowRate));
        agg.latestAnswer();
    }
}
