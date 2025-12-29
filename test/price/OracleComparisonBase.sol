// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {BaoTest} from "@bao-test/BaoTest.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "forge-std/console.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {DeployedAddresses} from "../DeployedAddresses.sol";
import {MainnetOracleAddresses} from "@harbor-price/price/MainnetOracleAddresses.sol";
import {HarborSingleFeedAndRateAggregator_v2} from "@harbor-price/price/HarborSingleFeedAndRateAggregator_v2.sol";
import {HarborDoubleFeedAndRateAggregator_v2} from "@harbor-price/price/HarborDoubleFeedAndRateAggregator_v2.sol";
import {HarborAggregator_v3} from "@harbor-price/HarborAggregator_v3.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UtcTimestampFormatter} from "@harbor-price/format/UtcTimestampFormatter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";

/// @title Oracle Comparison Base
/// @notice Shared comparison engine for forked mainnet oracle parity checks
/// @dev Forks mainnet at a fixed end block, then rolls within [START_BLOCK, endBlock] for sampling.
contract OracleComparisonBase is BaoTest {
    // Start block is deployment block
    uint256 constant START_BLOCK = DeployedAddresses.DEPLOYMENT_BLOCK;

    // Fixed end block for deterministic fork comparisons.
    // 24067873 == 2025-12-22 11:32:47 UTC
    uint256 constant END_BLOCK = 24_067_873;

    // End block captured at setUp time (fixed mainnet block)
    uint256 endTimestamp;
    uint256 endBlock;

    // Implementations - deployed once per test after initial rollFork
    HarborSingleFeedAndRateAggregator_v2 singleImpl;
    HarborDoubleFeedAndRateAggregator_v2 doubleImpl;

    struct OracleAnswer {
        uint256 minPrice;
        uint256 maxPrice;
        uint256 minRate;
        uint256 maxRate;
    }

    /*//////////////////////////////////////////////////////////////
                         CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Number of samples across the block range. Override for more thorough testing.
    function _iterations() internal pure virtual returns (uint256) {
        return 10;
    }

    /// @notice Block step derived from range and iterations
    function _blockStep() internal view returns (uint256) {
        return (endBlock - START_BLOCK) / _iterations();
    }

    /*//////////////////////////////////////////////////////////////
                         FORMATTING HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Format block info as "block# (YYYY-MM-DD HH:MM:SS UTC)"
    function _formatBlock(uint256 blockNum, uint256 timestamp) internal pure returns (string memory) {
        return string.concat(vm.toString(blockNum), " (", UtcTimestampFormatter.format(timestamp), ")");
    }

    /*//////////////////////////////////////////////////////////////
                            SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        // Fork mainnet at a fixed block for deterministic comparisons.
        vm.createSelectFork("mainnet", END_BLOCK);
        endBlock = END_BLOCK;
        endTimestamp = block.timestamp;
    }

    /// @notice Deploy implementations at the current block
    /// @dev Must be called after rollFork to START_BLOCK
    function _deployImplementations() internal {
        singleImpl = new HarborSingleFeedAndRateAggregator_v2(
            MainnetOracleAddresses.WSTETH,
            MainnetOracleAddresses.FXSAVE,
            MainnetOracleAddresses.SUSDE_USDE_FEED,
            MainnetOracleAddresses.WSTETH_STETH_FEED
        );
        doubleImpl = new HarborDoubleFeedAndRateAggregator_v2(
            MainnetOracleAddresses.WSTETH,
            MainnetOracleAddresses.FXSAVE,
            MainnetOracleAddresses.SUSDE_USDE_FEED,
            MainnetOracleAddresses.WSTETH_STETH_FEED
        );
    }

    /*//////////////////////////////////////////////////////////////
                           FACTORY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploy single feed oracle proxy
    /// @param oracleName Name for the oracle
    /// @param feed Chainlink price feed address
    /// @param divisor Price divisor (1 for most, 1e12 for MCAP)
    /// @param invertPrice Whether to invert the price (true for fxUSD oracles)
    function _deploySingleFeed(string memory oracleName, address feed, uint256 divisor, bool invertPrice)
        internal
        returns (IWrappedPriceOracle)
    {
        bytes memory initData = abi.encodeCall(
            HarborSingleFeedAndRateAggregator_v2.initialize,
            (
                address(this),
                oracleName,
                HarborSingleFeedAndRateAggregator_v2.RateSource.FXSAVE,
                feed,
                divisor,
                MainnetOracleAddresses.MAX_AGE,
                MainnetOracleAddresses.MAX_DEV,
                invertPrice
            )
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(singleImpl), initData);
        return IWrappedPriceOracle(address(proxy));
    }

    /// @notice Deploy double feed oracle proxy
    /// @param oracleName Name for the oracle
    /// @param firstFeed First Chainlink price feed (e.g., ETH/USD)
    /// @param secondFeed Second Chainlink price feed (e.g., BTC/USD)
    /// @param divisor Price divisor (1 for most, 1e12 for MCAP)
    /// @param invertPrice Whether to invert the price
    function _deployDoubleFeed(
        string memory oracleName,
        address firstFeed,
        address secondFeed,
        uint256 divisor,
        bool invertPrice
    ) internal returns (IWrappedPriceOracle) {
        bytes memory initData = abi.encodeCall(
            HarborDoubleFeedAndRateAggregator_v2.initialize,
            (
                address(this),
                oracleName,
                HarborDoubleFeedAndRateAggregator_v2.RateSource.WSTETH,
                firstFeed,
                secondFeed,
                divisor,
                MainnetOracleAddresses.MAX_AGE,
                MainnetOracleAddresses.MAX_DEV,
                MainnetOracleAddresses.MAX_AGE,
                MainnetOracleAddresses.MAX_DEV,
                invertPrice
            )
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(doubleImpl), initData);
        return IWrappedPriceOracle(address(proxy));
    }

    function _deployV3(address impl) internal returns (IWrappedPriceOracle) {
        // BaoFixedOwnable has no initialize - owner is set via constructor immutables
        ERC1967Proxy proxy = new ERC1967Proxy(impl, "");
        return IWrappedPriceOracle(address(proxy));
    }

    function _latest(IWrappedPriceOracle oracle) internal view returns (OracleAnswer memory answer) {
        (answer.minPrice, answer.maxPrice, answer.minRate, answer.maxRate) = oracle.latestAnswer();
    }

    /// @notice Try to get latest answer, returns success=false if oracle reverts (e.g., stale feed)
    /// @dev When it fails, logs the error details for debugging
    function _tryLatest(IWrappedPriceOracle oracle) internal view returns (bool success, OracleAnswer memory answer) {
        try oracle.latestAnswer() returns (uint256 minP, uint256 maxP, uint256 minR, uint256 maxR) {
            answer = OracleAnswer(minP, maxP, minR, maxR);
            success = true;
        } catch {
            // Note: can't log from view function, caller should log details
            success = false;
        }
    }

    function _logMismatch(string memory name, OracleAnswer memory baseA, OracleAnswer memory candA) internal view {
        console.log("  Block %s: MISMATCH", _formatBlock(block.number, block.timestamp));
        console.log("    base:      minPrice=%d, maxPrice=%d", baseA.minPrice, baseA.maxPrice);
        console.log("    base:      minRate=%d, maxRate=%d", baseA.minRate, baseA.maxRate);
        console.log("    candidate: minPrice=%d, maxPrice=%d", candA.minPrice, candA.maxPrice);
        console.log("    candidate: minRate=%d, maxRate=%d", candA.minRate, candA.maxRate);
        console.log("    oracle: %s", name);
    }

    /// @notice Log staleness details for known Chainlink feeds
    function _logFeedStaleness(IWrappedPriceOracle) internal view {
        // Query common Chainlink feeds to understand staleness
        address[] memory feeds = new address[](5);
        feeds[0] = MainnetOracleAddresses.ETH_USD_FEED;
        feeds[1] = MainnetOracleAddresses.BTC_USD_FEED;
        feeds[2] = MainnetOracleAddresses.EUR_USD_FEED;
        feeds[3] = MainnetOracleAddresses.XAU_USD_FEED;
        feeds[4] = MainnetOracleAddresses.STETH_USD_FEED;

        string[5] memory names = ["ETH/USD", "BTC/USD", "EUR/USD", "XAU/USD", "STETH/USD"];
        uint256[5] memory heartbeats = [uint256(3600), uint256(3600), uint256(86400), uint256(86400), uint256(86400)];

        console.log("    Feed staleness check (block.timestamp=%d):", block.timestamp);
        for (uint256 i = 0; i < feeds.length; i++) {
            AggregatorV3Interface feed = AggregatorV3Interface(feeds[i]);
            (, int256 answer,, uint256 updatedAt,) = feed.latestRoundData();
            uint256 age = block.timestamp - updatedAt;
            bool stale = age > heartbeats[i];
            console.log("    %s: updatedAt=%d, age=%d", names[i], updatedAt, age);
            console.log(
                "      answer=%s, heartbeat=%d, stale=%s",
                answer > 0 ? "positive" : "non-positive",
                heartbeats[i],
                stale
            );
        }
    }

    /*//////////////////////////////////////////////////////////////
                          COMPARISON LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Prepare fork state for comparison
    /// @dev Rolls fork to START_BLOCK and deploys implementations
    function _prepareForComparison() internal {
        vm.rollFork(START_BLOCK);
        _deployImplementations();
    }

    /// @notice Compare base vs candidate oracle across the block range
    function _compareOracle(IWrappedPriceOracle base, IWrappedPriceOracle candidate, string memory name) internal {
        uint256 originalBlock = block.number;
        vm.rollFork(START_BLOCK);

        uint256 step = _blockStep();
        uint256 mismatches = 0;
        uint256 skipped = 0;

        console.log(
            "Comparing %s: blocks %s to %s",
            name,
            _formatBlock(START_BLOCK, block.timestamp),
            _formatBlock(endBlock, endTimestamp)
        );
        console.log("  step: %d, iterations: %d", step, _iterations());

        for (uint256 i = 0; i <= _iterations(); i++) {
            uint256 sampleBlock = START_BLOCK + (i * step);
            vm.rollFork(sampleBlock);

            (bool baseOk, OracleAnswer memory baseA) = _tryLatest(base);
            (bool candOk, OracleAnswer memory candA) = _tryLatest(candidate);

            // Log and skip if either oracle reverts (stale feed data beyond tolerance)
            if (!baseOk || !candOk) {
                console.log("  STALE at block %d, timestamp %d", sampleBlock, block.timestamp);
                console.log("    baseOk=%s, candOk=%s", baseOk, candOk);
                _logFeedStaleness(candidate);
                skipped++;
                continue;
            }

            bool match_ = (baseA.minPrice == candA.minPrice) && (baseA.maxPrice == candA.maxPrice)
                && (baseA.minRate == candA.minRate) && (baseA.maxRate == candA.maxRate);

            if (!match_) {
                mismatches++;
                _logMismatch(name, baseA, candA);
            } else {
                // console.log("  Block %s: matched", _formatBlock(block.number, block.timestamp));
            }

            // NOTE: sampling schedule is fixed by (START_BLOCK, step, iterations)
        }

        console.log("%s: COMPLETE - %d samples, %d skipped (stale)", name, _iterations() + 1, skipped);
        console.log("  mismatches: %d", mismatches);
        vm.rollFork(originalBlock);
        assertEq(mismatches, 0, string.concat(name, ": found mismatches"));
    }

    /// @notice Compare base vs candidate oracle across the block range, with approximate matching for price only.
    /// @dev Rates are compared exactly; min/maxPrice are compared using BaoTest-compatible abs/rel tolerances.
    function _compareOracleApproxPrice(
        IWrappedPriceOracle base,
        IWrappedPriceOracle candidate,
        string memory name,
        uint256 absTolerance,
        uint256 relTolerance
    ) internal {
        uint256 originalBlock = block.number;
        vm.rollFork(START_BLOCK);

        uint256 step = _blockStep();
        uint256 mismatches = 0;
        uint256 skipped = 0;
        uint256 maxAbsPriceError = 0;
        uint256 maxRelPriceError = 0;

        console.log(
            "Comparing %s: blocks %s to %s",
            name,
            _formatBlock(START_BLOCK, block.timestamp),
            _formatBlock(endBlock, endTimestamp)
        );
        console.log("  step: %d, iterations: %d", step, _iterations());

        for (uint256 i = 0; i <= _iterations(); i++) {
            uint256 sampleBlock = START_BLOCK + (i * step);
            vm.rollFork(sampleBlock);

            (bool baseOk, OracleAnswer memory baseA) = _tryLatest(base);
            (bool candOk, OracleAnswer memory candA) = _tryLatest(candidate);

            // Skip if either oracle reverts (stale feed data)
            if (!baseOk || !candOk) {
                skipped++;
                continue;
            }

            {
                uint256 absMin =
                    baseA.minPrice > candA.minPrice ? baseA.minPrice - candA.minPrice : candA.minPrice - baseA.minPrice;
                if (absMin > maxAbsPriceError) {
                    maxAbsPriceError = absMin;
                }

                uint256 denomMin = baseA.minPrice > candA.minPrice ? baseA.minPrice : candA.minPrice;
                if (denomMin > 0) {
                    uint256 relMin = Math.mulDiv(absMin, 1e18, denomMin, Math.Rounding.Ceil);
                    if (relMin > maxRelPriceError) {
                        maxRelPriceError = relMin;
                    }
                }
            }

            {
                uint256 absMax =
                    baseA.maxPrice > candA.maxPrice ? baseA.maxPrice - candA.maxPrice : candA.maxPrice - baseA.maxPrice;
                if (absMax > maxAbsPriceError) {
                    maxAbsPriceError = absMax;
                }

                uint256 denomMax = baseA.maxPrice > candA.maxPrice ? baseA.maxPrice : candA.maxPrice;
                if (denomMax > 0) {
                    uint256 relMax = Math.mulDiv(absMax, 1e18, denomMax, Math.Rounding.Ceil);
                    if (relMax > maxRelPriceError) {
                        maxRelPriceError = relMax;
                    }
                }
            }

            bool priceMatch = isApprox(baseA.minPrice, candA.minPrice, absTolerance, relTolerance)
                && isApprox(baseA.maxPrice, candA.maxPrice, absTolerance, relTolerance);

            bool rateMatch = (baseA.minRate == candA.minRate) && (baseA.maxRate == candA.maxRate);

            if (!(priceMatch && rateMatch)) {
                mismatches++;
                _logMismatch(name, baseA, candA);
            }

            // NOTE: sampling schedule is fixed by (START_BLOCK, step, iterations)
        }

        console.log("%s: COMPLETE - %d samples, %d skipped (stale)", name, _iterations() + 1, skipped);
        console.log("  mismatches: %d", mismatches);
        console.log("%s: maxAbsPriceError=%d", name, maxAbsPriceError);
        console.log("%s: maxRelPriceError(1e18)=%d", name, maxRelPriceError);
        vm.rollFork(originalBlock);
        assertEq(mismatches, 0, string.concat(name, ": found mismatches"));
    }
}
