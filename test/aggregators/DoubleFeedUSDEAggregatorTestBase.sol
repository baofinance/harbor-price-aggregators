// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {MockAggregatorV3} from "@harbor-test/mock/MockAggregatorV3.sol";
import {MockSUSDe} from "@harbor-test/mock/MockSUSDe.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";
import {IBaoFixedOwnable} from "@bao/interfaces/IBaoFixedOwnable.sol";
import {SUSDeRateLib} from "@harbor-price/rates/SUSDeRateLib.sol";
import {ChainlinkFeedLib} from "@harbor-price/feeds/chainlink/ChainlinkFeedLib.sol";

/// @title Base test contract for double-feed v3 aggregators with sUSDe rate (USDE naming)
/// @notice Provides all tests; concrete contracts only implement factory + identity
abstract contract DoubleFeedUSDEAggregatorTestBase is Test {
    MockSUSDe mockSUSDe;
    MockAggregatorV3 mockFirstFeed;
    MockAggregatorV3 mockSecondFeed;

    IHarborPriceAggregatorV3 aggregator;

    uint256 constant DEFAULT_HEARTBEAT = 3600;
    uint256 constant VALID_SUSDE_RATE = 1.05e18;

    /// @dev The fixed owner address from HarborAggregator_v3
    address constant OWNER = 0x9bABfC1A1952a6ed2caC1922BFfE80c0506364a2;

    /// @dev ERC1967 implementation slot
    bytes32 constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @notice Returns the contract name (e.g., "Aggregator_USDE_BTC")
    function _contractName() internal pure virtual returns (string memory);

    function _createAggregator(
        address susde,
        address firstFeed,
        uint256 firstHeartbeat,
        address secondFeed,
        uint256 secondHeartbeat,
        uint256 divisor,
        bool invert
    ) internal virtual returns (IHarborPriceAggregatorV3);

    function _createWithZeroSusde() internal virtual;
    function _createWithZeroFirstFeed() internal virtual;
    function _createWithZeroSecondFeed() internal virtual;
    function _createWithZeroDivisor() internal virtual;

    function _expectedBaseName() internal pure virtual returns (string memory) {
        return _parseContractName(1);
    }

    function _expectedQuoteName() internal pure virtual returns (string memory) {
        return _parseContractName(2);
    }

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

    function setUp() public virtual {
        vm.warp(100_000);

        mockSUSDe = new MockSUSDe();
        mockFirstFeed = new MockAggregatorV3(8);
        mockSecondFeed = new MockAggregatorV3(8);

        mockSUSDe.setAssetsPerShare(VALID_SUSDE_RATE);
        mockFirstFeed.setAnswer(1e8, block.timestamp); // USDe/USD = 1.0
        mockSecondFeed.setAnswer(50000e8, block.timestamp); // BTC/USD = 50000

        aggregator = _createAggregator(
            address(mockSUSDe),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    function test_constructor_revertsOnZeroSusde() public {
        vm.expectRevert();
        _createWithZeroSusde();
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
        assertEq(aggregator.rateProvider(), address(mockSUSDe));
    }

    function test_latestAnswer_returnsValidTuple() public view {
        (uint256 p1, uint256 p2, uint256 r1, uint256 r2) = aggregator.latestAnswer();
        assertGt(p1, 0, "price1 > 0");
        assertEq(p1, p2, "price1 == price2");
        assertEq(r1, VALID_SUSDE_RATE, "rate1");
        assertEq(r1, r2, "rate1 == rate2");
    }

    function test_latestAnswer_staleFirstFeed_reverts() public {
        uint256 staleTime = block.timestamp - DEFAULT_HEARTBEAT - 43;
        mockFirstFeed.setAnswer(1e8, staleTime);

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
        mockSecondFeed.setAnswer(50000e8, staleTime);

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

    function test_latestAnswer_rateBelowMin_reverts() public {
        uint256 lowRate = 0.8e18;
        mockSUSDe.setAssetsPerShare(lowRate);

        vm.expectRevert(abi.encodeWithSelector(SUSDeRateLib.InvalidRate.selector, lowRate));
        aggregator.latestAnswer();
    }

    function test_upgrade() public {
        IHarborPriceAggregatorV3 impl1 = _createAggregator(
            address(mockSUSDe),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl1), "");
        IHarborPriceAggregatorV3 proxied = IHarborPriceAggregatorV3(address(proxy));

        (uint256 price1, , , ) = proxied.latestAnswer();
        assertGt(price1, 0, "impl1 price should be positive");

        IHarborPriceAggregatorV3 impl2 = _createAggregator(
            address(mockSUSDe),
            address(mockFirstFeed),
            DEFAULT_HEARTBEAT,
            address(mockSecondFeed),
            DEFAULT_HEARTBEAT,
            2,
            false
        );

        address notOwner = makeAddr("notOwner");
        vm.prank(notOwner);
        vm.expectRevert(IBaoFixedOwnable.Unauthorized.selector);
        UUPSUpgradeable(address(proxy)).upgradeToAndCall(address(impl2), "");

        vm.prank(OWNER);
        UUPSUpgradeable(address(proxy)).upgradeToAndCall(address(impl2), "");

        (uint256 price2, , , ) = proxied.latestAnswer();
        assertNotEq(price2, price1, "Price should differ after upgrade to impl with different divisor");

        address newImpl = address(uint160(uint256(vm.load(address(proxy), IMPLEMENTATION_SLOT))));
        assertEq(newImpl, address(impl2), "Implementation slot should point to impl2");
    }
}
