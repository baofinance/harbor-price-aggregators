// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28 <0.9.0;

import {Vm} from "forge-std/Vm.sol";
import {console2} from "forge-std/console2.sol";

import {DeploymentBase} from "@bao-script/deployment/DeploymentBase.sol";
import {DeploymentDataMemory} from "@bao-script/deployment/DeploymentDataMemory.sol";
import {DeploymentJson} from "@bao-script/deployment/DeploymentJson.sol";
import {DeploymentJsonScript} from "@bao-script/deployment/DeploymentJsonScript.sol";
import {LibString} from "@solady/utils/LibString.sol";

import {DataType} from "@bao-script/deployment/DeploymentKeys.sol";

import {HarborSingleFeedAndRateAggregator_v2} from "@harbor-price/price/HarborSingleFeedAndRateAggregator_v2.sol";
import {HarborDoubleFeedAndRateAggregator_v2} from "@harbor-price/price/HarborDoubleFeedAndRateAggregator_v2.sol";

/**
 * @title HarborDeploymentJsonScript
 * @notice Harbor-specific deployment contract with Stem proxy management
 * @dev Extends DeploymentJsonScript with Harbor-specific schema and deployment methods.
 *
 *      Features:
 *      - All proxies use Stem_v1 for upgrade control
 *      - Type-safe enum-based API
 *      - Production-focused deployment methods
 *      - Delegates actual deployment to specialized libraries
 *      - BaoFactory address read from JSON config (no variant selection)
 */

abstract contract PriceAggregatorsDeploymentJsonScript is DeploymentJsonScript {
    using LibString for string;

    // =========================================================================
    // BaoFactory from JSON
    // =========================================================================

    error FactoryNotDeployed(address factory);
    error FactoryOwnerMismatch(address expected, address actual);

    // =========================================================================
    // Errors
    // =========================================================================

    error ChainIdMismatch(uint256 expected, uint256 actual);
    error SaltMismatch(string expected, string actual);

    // =========================================================================
    // Contract Keys
    // =========================================================================

    string public constant PREFIX = "prefix";
    string public constant TREASURY = "treasury";
    string public constant NETWORKS = "networks";
    // with in each network: TODO: set this up in start()

    string public constant FEEDS = "feeds";

    string public constant IMPLEMENTATIONS = "implementations";
    string public constant SINGLE_FEED_AGGREGATOR = "HarborSingleFeedAndRateAggregator_v2";
    string public constant DOUBLE_FEED_AGGREGATOR = "HarborDoubleFeedAndRateAggregator_v2";

    // all the price feeds
    string public constant FXUSD_ETH_FEED = "contracts.fxUSD-ETH";
    string public constant FXUSD_BTC_FEED = "contracts.fxUSD-BTC";
    string public constant FXUSD_EUR_FEED = "contracts.fxUSD-EUR";
    string public constant FXUSD_XAU_FEED = "contracts.fxUSD-GOLD";
    string public constant FXUSD_MCAP_FEED = "contracts.fxUSD-MCAP";
    string public constant STETH_BTC_FEED = "contracts.stETH-BTC";
    string public constant STETH_EUR_FEED = "contracts.stETH-EUR";
    string public constant STETH_XAU_FEED = "contracts.stETH-GOLD";
    string public constant STETH_MCAP_FEED = "contracts.stETH-MCAP";
    // within each price feed
    string public constant PRICE_ORACLE_COLLATERAL = "collateral"; // should match the name
    string public constant PRICE_ORACLE_PEGGED_TICKER = "peggedTicker"; // should match the name
    string public constant PRICE_ORACLE_IMPLEMENTATION_TYPE = "implementation.type";
    // initialize fields, after owner & name
    string public constant PRICE_ORACLE_RATE_SOURCE = "rateSource";
    string public constant PRICE_ORACLE_FIRST_FEED = "firstFeed";
    string public constant PRICE_ORACLE_SECOND_FEED = "secondFeed"; // only double
    string public constant PRICE_ORACLE_PRICE_DIVISOR = "priceDivisor";
    string public constant PRICE_ORACLE_FIRST_FEED_MAX_AGE = "firstFeedMaxAge";
    string public constant PRICE_ORACLE_FIRST_FEED_MAX_DEV = "firstFeedMaxDev";
    string public constant PRICE_ORACLE_SECOND_FEED_MAX_AGE = "secondFeedMaxAge"; // only double
    string public constant PRICE_ORACLE_SECOND_FEED_MAX_DEV = "secondFeedMaxDev"; // only double
    string public constant PRICE_ORACLE_INVERT_PRICE = "invertPrice";

    // ============================================================================
    // Configuration
    // ============================================================================

    function addPriceOracle(string memory contractKey) private {
        addProxy(contractKey);

        addStringKey(string.concat(contractKey, ".name"));
        addStringKey(string.concat(contractKey, ".", PRICE_ORACLE_IMPLEMENTATION_TYPE));

        addStringKey(string.concat(contractKey, ".", PRICE_ORACLE_COLLATERAL));
        addStringKey(string.concat(contractKey, ".", PRICE_ORACLE_PEGGED_TICKER));

        addStringKey(string.concat(contractKey, ".", PRICE_ORACLE_RATE_SOURCE));

        addAddressKey(string.concat(contractKey, ".", PRICE_ORACLE_FIRST_FEED));
        addAddressKey(string.concat(contractKey, ".", PRICE_ORACLE_SECOND_FEED)); // only double
        addUintKey(string.concat(contractKey, ".", PRICE_ORACLE_PRICE_DIVISOR));
        addUintKey(string.concat(contractKey, ".", PRICE_ORACLE_FIRST_FEED_MAX_AGE));
        addUintKey(string.concat(contractKey, ".", PRICE_ORACLE_FIRST_FEED_MAX_DEV));
        addUintKey(string.concat(contractKey, ".", PRICE_ORACLE_SECOND_FEED_MAX_AGE)); // only double
        addUintKey(string.concat(contractKey, ".", PRICE_ORACLE_SECOND_FEED_MAX_DEV)); // only double
        addBoolKey(string.concat(contractKey, ".", PRICE_ORACLE_INVERT_PRICE));
    }

    constructor() {
        addStringKey(PREFIX);
        addAddressKey(TREASURY);

        addKey(NETWORKS);
        addKey(IMPLEMENTATIONS);
        addAddressKey(string.concat(IMPLEMENTATIONS, ".", SINGLE_FEED_AGGREGATOR));
        addAddressKey(string.concat(IMPLEMENTATIONS, ".", DOUBLE_FEED_AGGREGATOR));

        // TODO: this should use the dynamic key facility
        addKey(FEEDS);
        addAddressKey(string.concat(FEEDS, ".", "USDC_USD_FEED"));
        addAddressKey(string.concat(FEEDS, ".", "ETH_USD_FEED"));
        addAddressKey(string.concat(FEEDS, ".", "BTC_USD_FEED"));
        addAddressKey(string.concat(FEEDS, ".", "EUR_USD_FEED"));
        addAddressKey(string.concat(FEEDS, ".", "XAU_USD_FEED"));
        addAddressKey(string.concat(FEEDS, ".", "MCAP_USD_FEED"));
        addAddressKey(string.concat(FEEDS, ".", "STETH_USD_FEED"));
        addAddressKey(string.concat(FEEDS, ".", "STETH_ETH_FEED"));

        addPriceOracle(FXUSD_ETH_FEED);
        addPriceOracle(FXUSD_BTC_FEED);
        addPriceOracle(FXUSD_EUR_FEED);
        addPriceOracle(FXUSD_XAU_FEED);
        addPriceOracle(FXUSD_MCAP_FEED);
        addPriceOracle(STETH_BTC_FEED);
        addPriceOracle(STETH_EUR_FEED);
        addPriceOracle(STETH_XAU_FEED);
        addPriceOracle(STETH_MCAP_FEED);
    }

    // ============================================================================
    // PriceOracle
    // ============================================================================

    function _deployPriceOracle(string memory contractKey) internal {
        console2.log("Deploying Price Oracle %s ...", contractKey);

        // get the contract identifie
        string memory collateral = _getString(string.concat(contractKey, ".", PRICE_ORACLE_COLLATERAL));
        console2.log(" - Collateral: %s", collateral);
        string memory peggedTicker = _getString(string.concat(contractKey, ".", PRICE_ORACLE_PEGGED_TICKER));
        console2.log(" - Pegged Ticker: %s", peggedTicker);
        string memory name = string.concat(collateral, "-", peggedTicker);
        console2.log(" - Name: %s", name);
        _setString(string.concat(contractKey, ".name"), name);

        // set up the implementation-specific data
        bytes memory initData;
        string memory implementationName;
        bytes memory implementationCreationCode;

        string memory implementationType = _getString(string.concat(contractKey, ".", PRICE_ORACLE_IMPLEMENTATION_TYPE));

        string memory rateSourceId = _getString(string.concat(contractKey, ".", PRICE_ORACLE_RATE_SOURCE)).upper();
        if (implementationType.eq("HarborSingleFeedAndRateAggregator_v2")) {
            HarborSingleFeedAndRateAggregator_v2.RateSource rateSource;
            if (rateSourceId.eq("WSTETH")) {
                rateSource = HarborSingleFeedAndRateAggregator_v2.RateSource.WSTETH;
            } else if (rateSourceId.eq("FXSAVE")) {
                rateSource = HarborSingleFeedAndRateAggregator_v2.RateSource.FXSAVE;
            } else if (rateSourceId.eq("SUSDE_CHAINLINK")) {
                rateSource = HarborSingleFeedAndRateAggregator_v2.RateSource.SUSDE_CHAINLINK;
            } else if (rateSourceId.eq("WSTETH_CHAINLINK")) {
                rateSource = HarborSingleFeedAndRateAggregator_v2.RateSource.WSTETH_CHAINLINK;
            } else {
                revert(string.concat("Unknown rate source: ", rateSourceId));
            }

            initData = abi.encodeCall(
                HarborSingleFeedAndRateAggregator_v2.initialize,
                (
                    _getAddress(OWNER),
                    name,
                    rateSource,
                    _getAddress(string.concat(contractKey, ".", PRICE_ORACLE_FIRST_FEED)),
                    _getUint(string.concat(contractKey, ".", PRICE_ORACLE_PRICE_DIVISOR)),
                    uint64(_getUint(string.concat(contractKey, ".", PRICE_ORACLE_FIRST_FEED_MAX_AGE))),
                    _getUint(string.concat(contractKey, ".", PRICE_ORACLE_FIRST_FEED_MAX_DEV)),
                    _getBool(string.concat(contractKey, ".", PRICE_ORACLE_INVERT_PRICE))
                )
            );

            implementationName = type(HarborSingleFeedAndRateAggregator_v2).name;
            implementationCreationCode = type(HarborSingleFeedAndRateAggregator_v2).creationCode;
        } else if (implementationType.eq("HarborDoubleFeedAndRateAggregator_v2")) {
            HarborDoubleFeedAndRateAggregator_v2.RateSource rateSource;
            if (rateSourceId.eq("WSTETH")) {
                rateSource = HarborDoubleFeedAndRateAggregator_v2.RateSource.WSTETH;
            } else if (rateSourceId.eq("FXSAVE")) {
                rateSource = HarborDoubleFeedAndRateAggregator_v2.RateSource.FXSAVE;
            } else if (rateSourceId.eq("SUSDE_CHAINLINK")) {
                rateSource = HarborDoubleFeedAndRateAggregator_v2.RateSource.SUSDE_CHAINLINK;
            } else if (rateSourceId.eq("WSTETH_CHAINLINK")) {
                rateSource = HarborDoubleFeedAndRateAggregator_v2.RateSource.WSTETH_CHAINLINK;
            } else {
                revert(string.concat("Unknown rate source: ", rateSourceId));
            }
            initData = abi.encodeCall(
                HarborDoubleFeedAndRateAggregator_v2.initialize,
                (
                    _getAddress(OWNER),
                    name,
                    rateSource,
                    _getAddress(string.concat(contractKey, ".", PRICE_ORACLE_FIRST_FEED)),
                    _getAddress(string.concat(contractKey, ".", PRICE_ORACLE_SECOND_FEED)),
                    _getUint(string.concat(contractKey, ".", PRICE_ORACLE_PRICE_DIVISOR)),
                    uint64(_getUint(string.concat(contractKey, ".", PRICE_ORACLE_FIRST_FEED_MAX_AGE))),
                    _getUint(string.concat(contractKey, ".", PRICE_ORACLE_FIRST_FEED_MAX_DEV)),
                    uint64(_getUint(string.concat(contractKey, ".", PRICE_ORACLE_SECOND_FEED_MAX_AGE))),
                    _getUint(string.concat(contractKey, ".", PRICE_ORACLE_SECOND_FEED_MAX_DEV)),
                    _getBool(string.concat(contractKey, ".", PRICE_ORACLE_INVERT_PRICE))
                )
            );

            implementationName = type(HarborDoubleFeedAndRateAggregator_v2).name;
            implementationCreationCode = type(HarborDoubleFeedAndRateAggregator_v2).creationCode;
        } else {
            revert(string.concat("unknown implementation.type:", implementationType));
        }

        deployProxy(
            contractKey,
            "priceoracle",
            _getAddress(string.concat(IMPLEMENTATIONS, ".", implementationType)),
            initData,
            implementationName,
            implementationCreationCode,
            _getAddress(SESSION_DEPLOYER)
        );
        _save();
    }
}
