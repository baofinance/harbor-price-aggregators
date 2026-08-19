// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {IWstETH} from "@bao/interfaces/IWstETH.sol";
import {IFxSAVE} from "@harbor-price/interfaces/IFxSAVE.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";
import {Aggregator_fxUSD_STRC_mainnet} from "@harbor-price/mainnet/Aggregator_fxUSD_STRC_mainnet.sol";
import {Aggregator_stETH_STRC_mainnet} from "@harbor-price/mainnet/Aggregator_stETH_STRC_mainnet.sol";
import {Aggregator_fxUSD_SPCX_mainnet} from "@harbor-price/mainnet/Aggregator_fxUSD_SPCX_mainnet.sol";
import {Aggregator_stETH_SPCX_mainnet} from "@harbor-price/mainnet/Aggregator_stETH_SPCX_mainnet.sol";
import {STRC_USD} from "@harbor-price/feeds/chainlink/mainnet/STRC_USD.sol";
import {SPCX_USD} from "@harbor-price/feeds/chainlink/mainnet/SPCX_USD.sol";
import {STETH_USD} from "@harbor-price/feeds/chainlink/mainnet/STETH_USD.sol";
import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";

/// @notice Mainnet fork checks that STRC/SPCX aggregators match live Chainlink + rate sources.
/// @dev forge test --match-path test/mainnet/StrcSpcxOraclesFork.t.sol --fork-url $MAINNET_RPC_URL -vv
contract StrcSpcxOraclesForkTest is Test {
    IHarborPriceAggregatorV3 internal fxUsdStrc;
    IHarborPriceAggregatorV3 internal stEthStrc;
    IHarborPriceAggregatorV3 internal fxUsdSpcx;
    IHarborPriceAggregatorV3 internal stEthSpcx;

    uint256 internal strcUsd;
    uint256 internal spcxUsd;
    uint256 internal stethUsd;
    uint256 internal fxSaveRate;
    uint256 internal wstethRate;

    function setUp() public {
        // Prefer an already-selected `--fork-url`. Only then fall back to the `mainnet` RPC alias.
        if (block.chainid != 1) {
            try vm.createSelectFork("mainnet") {} catch {
                vm.skip(true);
            }
        }
        if (block.chainid != 1) vm.skip(true);

        fxUsdStrc = IHarborPriceAggregatorV3(address(new Aggregator_fxUSD_STRC_mainnet()));
        stEthStrc = IHarborPriceAggregatorV3(address(new Aggregator_stETH_STRC_mainnet()));
        fxUsdSpcx = IHarborPriceAggregatorV3(address(new Aggregator_fxUSD_SPCX_mainnet()));
        stEthSpcx = IHarborPriceAggregatorV3(address(new Aggregator_stETH_SPCX_mainnet()));

        strcUsd = _normalizedFeed(STRC_USD.FEED);
        spcxUsd = _normalizedFeed(SPCX_USD.FEED);
        stethUsd = _normalizedFeed(STETH_USD.FEED);
        fxSaveRate = IFxSAVE(MainnetRateSources.FXSAVE).convertToAssets(1e18);
        wstethRate = IWstETH(MainnetRateSources.WSTETH).getStETHByWstETH(1e18);
    }

    function test_fork_fxUSD_STRC_matchesLiveFeeds() public view {
        uint256 expectedPrice = Math.mulDiv(1e18, 1e18, strcUsd);
        _assertOracle("fxUSD/STRC", fxUsdStrc, "fxUSD", "STRC", expectedPrice, fxSaveRate, MainnetRateSources.FXSAVE);
        _logUsd("STRC/USD (Chainlink)", strcUsd);
    }

    function test_fork_fxUSD_SPCX_matchesLiveFeeds() public view {
        uint256 expectedPrice = Math.mulDiv(1e18, 1e18, spcxUsd);
        _assertOracle("fxUSD/SPCX", fxUsdSpcx, "fxUSD", "SPCX", expectedPrice, fxSaveRate, MainnetRateSources.FXSAVE);
        _logUsd("SPCX/USD (Chainlink)", spcxUsd);
    }

    function test_fork_stETH_STRC_matchesLiveFeeds() public view {
        uint256 expectedPrice = Math.mulDiv(stethUsd, 1e18, strcUsd);
        _assertOracle("stETH/STRC", stEthStrc, "stETH", "STRC", expectedPrice, wstethRate, MainnetRateSources.WSTETH);
        _logUsd("stETH/USD (Chainlink)", stethUsd);
        _logUsd("STRC/USD (Chainlink)", strcUsd);
    }

    function test_fork_stETH_SPCX_matchesLiveFeeds() public view {
        uint256 expectedPrice = Math.mulDiv(stethUsd, 1e18, spcxUsd);
        _assertOracle("stETH/SPCX", stEthSpcx, "stETH", "SPCX", expectedPrice, wstethRate, MainnetRateSources.WSTETH);
        _logUsd("stETH/USD (Chainlink)", stethUsd);
        _logUsd("SPCX/USD (Chainlink)", spcxUsd);
    }

    function test_fork_quoteFeedsAreInStockPriceRange() public view {
        // STRC Stretch preferred trades near $100 par; SPCX Class A is a large-cap equity.
        assertGt(strcUsd, 50e18, "STRC/USD too low");
        assertLt(strcUsd, 150e18, "STRC/USD too high");
        assertGt(spcxUsd, 50e18, "SPCX/USD too low");
        assertLt(spcxUsd, 400e18, "SPCX/USD too high");
        _logUsd("STRC/USD", strcUsd);
        _logUsd("SPCX/USD", spcxUsd);
    }

    function _assertOracle(
        string memory label,
        IHarborPriceAggregatorV3 oracle,
        string memory expectedBase,
        string memory expectedQuote,
        uint256 expectedPrice,
        uint256 expectedRate,
        address expectedRateProvider
    ) internal view {
        (uint256 minPrice, uint256 maxPrice, uint256 minRate, uint256 maxRate) = oracle.latestAnswer();

        console.log("===", label, "===");
        _logE18("price", minPrice);
        _logE18("expected price", expectedPrice);
        _logE18("rate", minRate);
        _logE18("expected rate", expectedRate);
        console.log("oracleName:", oracle.oracleName());
        console.log("rateProvider:", oracle.rateProvider());
        console.log("");

        assertEq(oracle.baseName(), expectedBase, "baseName");
        assertEq(oracle.quoteName(), expectedQuote, "quoteName");
        assertEq(oracle.oracleName(), string.concat(expectedBase, "/", expectedQuote), "oracleName");
        assertEq(oracle.rateProvider(), expectedRateProvider, "rateProvider");
        assertEq(oracle.version(), 3, "version");

        assertEq(minPrice, expectedPrice, "minPrice");
        assertEq(maxPrice, expectedPrice, "maxPrice");
        assertEq(minRate, expectedRate, "minRate");
        assertEq(maxRate, expectedRate, "maxRate");
        assertEq(minPrice, maxPrice, "price band");
        assertEq(minRate, maxRate, "rate band");
    }

    function _normalizedFeed(address feed) internal view returns (uint256) {
        AggregatorV3Interface agg = AggregatorV3Interface(feed);
        (, int256 answer, , uint256 updatedAt, ) = agg.latestRoundData();
        require(answer > 0, "non-positive feed");
        require(updatedAt != 0, "feed never updated");
        uint8 decimals = agg.decimals();
        require(decimals <= 18, "unexpected decimals");
        return uint256(answer) * (10 ** (18 - decimals));
    }

    function _logUsd(string memory label, uint256 valueE18) internal pure {
        uint256 dollars = valueE18 / 1e18;
        uint256 cents = (valueE18 % 1e18) / 1e16;
        console.log(label);
        console.log("  $", dollars);
        console.log("  cents (2dp):", cents);
        console.log("  raw 1e18:", valueE18);
    }

    function _logE18(string memory label, uint256 valueE18) internal pure {
        uint256 whole = valueE18 / 1e18;
        uint256 frac = (valueE18 % 1e18) / 1e14; // 4 dp
        console.log(label);
        console.log("  whole:", whole);
        console.log("  4dp:", frac);
        console.log("  raw 1e18:", valueE18);
    }
}
