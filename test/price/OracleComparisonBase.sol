// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {DeployedAddresses} from "../DeployedAddresses.sol";
import {MainnetOracleAddresses} from "@harbor-price/price/MainnetOracleAddresses.sol";
import {HarborSingleFeedAndRateAggregator_v2} from "@harbor-price/price/HarborSingleFeedAndRateAggregator_v2.sol";
import {HarborDoubleFeedAndRateAggregator_v2} from "@harbor-price/price/HarborDoubleFeedAndRateAggregator_v2.sol";
import {HarborPriceAggregator_v3} from "@harbor-price/price/HarborPriceAggregator_v3.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @title Oracle Comparison Base
/// @notice Shared comparison engine for forked mainnet oracle parity checks
/// @dev Forks mainnet at a fixed end block, then rolls within [START_BLOCK, endBlock] for sampling.
contract OracleComparisonBase is Test {
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

    function _pad2(uint256 value) internal pure returns (string memory) {
        if (value < 10) {
            return string.concat("0", vm.toString(value));
        }
        return vm.toString(value);
    }

    /// @notice Format timestamp as YYYY-MM-DD HH:MM:SS UTC
    function _formatTimestamp(uint256 timestamp) internal pure returns (string memory) {
        // Calculate date components from unix timestamp
        uint256 z = timestamp / 86400 + 719468;
        uint256 era = z / 146097;
        uint256 doe = z - era * 146097;
        uint256 yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
        uint256 y = yoe + era * 400;
        uint256 doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
        uint256 mp = (5 * doy + 2) / 153;
        uint256 d = doy - (153 * mp + 2) / 5 + 1;
        uint256 m = mp < 10 ? mp + 3 : mp - 9;
        if (m <= 2) y += 1;

        // Calculate time components
        uint256 secondsInDay = timestamp % 86400;
        uint256 h = secondsInDay / 3600;
        uint256 min = (secondsInDay % 3600) / 60;
        uint256 s = secondsInDay % 60;

        string memory date = string.concat(vm.toString(y), "-", _pad2(m), "-", _pad2(d));
        string memory time = string.concat(_pad2(h), ":", _pad2(min), ":", _pad2(s));
        return string.concat(date, " ", time, " UTC");
    }

    /// @notice Format block info as "block# (YYYY-MM-DD HH:MM:SS UTC)"
    function _formatBlock(uint256 blockNum, uint256 timestamp) internal pure returns (string memory) {
        return string.concat(vm.toString(blockNum), " (", _formatTimestamp(timestamp), ")");
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
    function _deploySingleFeed(
        string memory oracleName,
        address feed,
        uint256 divisor,
        bool invertPrice
    ) internal returns (IWrappedPriceOracle) {
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
        bytes memory initData = abi.encodeCall(HarborPriceAggregator_v3.initialize, (address(this)));
        ERC1967Proxy proxy = new ERC1967Proxy(impl, initData);
        return IWrappedPriceOracle(address(proxy));
    }

    function _latest(IWrappedPriceOracle oracle) internal view returns (OracleAnswer memory answer) {
        (answer.minPrice, answer.maxPrice, answer.minRate, answer.maxRate) = oracle.latestAnswer();
    }

    function _logMismatch(string memory name, OracleAnswer memory baseA, OracleAnswer memory candA) internal view {
        console.log("  Block %s: MISMATCH", _formatBlock(block.number, block.timestamp));
        console.log("    base:      minPrice=%d, maxPrice=%d", baseA.minPrice, baseA.maxPrice);
        console.log("    base:      minRate=%d, maxRate=%d", baseA.minRate, baseA.maxRate);
        console.log("    candidate: minPrice=%d, maxPrice=%d", candA.minPrice, candA.maxPrice);
        console.log("    candidate: minRate=%d, maxRate=%d", candA.minRate, candA.maxRate);
        console.log("    oracle: %s", name);
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
        uint256 startBlock = block.number;
        uint256 step = _blockStep();
        uint256 count = 0;
        uint256 mismatches = 0;

        console.log(
            "Comparing %s: blocks %s to %s",
            name,
            _formatBlock(block.number, block.timestamp),
            _formatBlock(endBlock, endTimestamp)
        );
        console.log("  step: %d, iterations: %d", step, _iterations());

        uint256 nextBlock = block.number;
        while (true) {
            OracleAnswer memory baseA = _latest(base);
            OracleAnswer memory candA = _latest(candidate);

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

            count++;
            nextBlock += step;
            if (nextBlock <= endBlock) {
                vm.rollFork(nextBlock);
            } else {
                break;
            }
        }

        console.log("%s: COMPLETE - %d samples, %d mismatches", name, count, mismatches);
        vm.rollFork(startBlock);
        assertEq(mismatches, 0, string.concat(name, ": found mismatches"));
    }
}
