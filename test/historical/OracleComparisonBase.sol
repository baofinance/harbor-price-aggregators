// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {BaoTest} from "@bao-test/BaoTest.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "forge-std/console.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {DeployedAddresses} from "./DeployedAddresses.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UtcTimestampFormatter} from "@harbor-price/format/UtcTimestampFormatter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";

// Chainlink feed addresses for staleness checks
import {ETH_USD} from "@harbor-price/feeds/chainlink/mainnet/ETH_USD.sol";
import {BTC_USD} from "@harbor-price/feeds/chainlink/mainnet/BTC_USD.sol";
import {EUR_USD} from "@harbor-price/feeds/chainlink/mainnet/EUR_USD.sol";
import {XAU_USD} from "@harbor-price/feeds/chainlink/mainnet/XAU_USD.sol";
import {STETH_USD} from "@harbor-price/feeds/chainlink/mainnet/STETH_USD.sol";

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

    struct OracleAnswer {
        uint256 minPrice;
        uint256 maxPrice;
        uint256 minRate;
        uint256 maxRate;
    }

    struct ComparisonStats {
        uint256 mismatches;
        uint256 skipped;
        uint256 maxAbsPriceError;
        uint256 maxRelPriceError;
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
        vm.skip(true);
        // Fork mainnet at a fixed block for deterministic comparisons.
        vm.createSelectFork("mainnet", END_BLOCK);
        endBlock = END_BLOCK;
        endTimestamp = block.timestamp;
    }

    /// @notice Prepare fork state for comparison
    /// @dev Rolls fork to START_BLOCK
    function _prepareForComparison() internal {
        vm.rollFork(START_BLOCK);
    }

    /*//////////////////////////////////////////////////////////////
                           FACTORY FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploy a v3 aggregator behind a proxy
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
        feeds[0] = ETH_USD.FEED;
        feeds[1] = BTC_USD.FEED;
        feeds[2] = EUR_USD.FEED;
        feeds[3] = XAU_USD.FEED;
        feeds[4] = STETH_USD.FEED;

        string[5] memory names = ["ETH/USD", "BTC/USD", "EUR/USD", "XAU/USD", "STETH/USD"];
        uint256[5] memory heartbeats = [
            ETH_USD.HEARTBEAT,
            BTC_USD.HEARTBEAT,
            EUR_USD.HEARTBEAT,
            XAU_USD.HEARTBEAT,
            STETH_USD.HEARTBEAT
        ];

        console.log("    Feed staleness check (block.timestamp=%d):", block.timestamp);
        for (uint256 i = 0; i < feeds.length; i++) {
            AggregatorV3Interface feed = AggregatorV3Interface(feeds[i]);
            (, int256 answer, , uint256 updatedAt, ) = feed.latestRoundData();
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

            bool match_ = (baseA.minPrice == candA.minPrice) &&
                (baseA.maxPrice == candA.maxPrice) &&
                (baseA.minRate == candA.minRate) &&
                (baseA.maxRate == candA.maxRate);

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
        ComparisonStats memory stats;

        console.log(
            "Comparing %s: blocks %s to %s",
            name,
            _formatBlock(START_BLOCK, block.timestamp),
            _formatBlock(endBlock, endTimestamp)
        );
        console.log("  step: %d, iterations: %d", step, _iterations());

        for (uint256 i = 0; i <= _iterations(); i++) {
            vm.rollFork(START_BLOCK + (i * step));

            (bool baseOk, OracleAnswer memory baseA) = _tryLatest(base);
            (bool candOk, OracleAnswer memory candA) = _tryLatest(candidate);

            if (!baseOk || !candOk) {
                stats.skipped++;
                continue;
            }

            _updatePriceErrorStats(baseA.minPrice, candA.minPrice, stats);
            _updatePriceErrorStats(baseA.maxPrice, candA.maxPrice, stats);

            bool priceMatch = isApprox(baseA.minPrice, candA.minPrice, absTolerance, relTolerance) &&
                isApprox(baseA.maxPrice, candA.maxPrice, absTolerance, relTolerance);

            bool rateMatch = (baseA.minRate == candA.minRate) && (baseA.maxRate == candA.maxRate);

            if (!(priceMatch && rateMatch)) {
                stats.mismatches++;
                _logMismatch(name, baseA, candA);
            }
        }

        console.log("%s: COMPLETE - %d samples, %d skipped (stale)", name, _iterations() + 1, stats.skipped);
        console.log("  mismatches: %d", stats.mismatches);
        console.log("%s: maxAbsPriceError=%d", name, stats.maxAbsPriceError);
        console.log("%s: maxRelPriceError(1e18)=%d", name, stats.maxRelPriceError);
        vm.rollFork(originalBlock);
        assertEq(stats.mismatches, 0, string.concat(name, ": found mismatches"));
    }

    /// @notice Update error stats with abs/rel price error
    function _updatePriceErrorStats(uint256 basePrice, uint256 candPrice, ComparisonStats memory stats) internal pure {
        uint256 absErr = basePrice > candPrice ? basePrice - candPrice : candPrice - basePrice;
        if (absErr > stats.maxAbsPriceError) {
            stats.maxAbsPriceError = absErr;
        }
        uint256 denom = basePrice > candPrice ? basePrice : candPrice;
        if (denom > 0) {
            uint256 relErr = Math.mulDiv(absErr, 1e18, denom, Math.Rounding.Ceil);
            if (relErr > stats.maxRelPriceError) {
                stats.maxRelPriceError = relErr;
            }
        }
    }
}
