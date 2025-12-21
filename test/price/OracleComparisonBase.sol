// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";
import {IWrappedPriceOracle} from "src/interfaces/IWrappedPriceOracle.sol";
import {DeployedAddresses, MainnetAddresses} from "../DeployedAddresses.sol";
import {HarborSingleFeedAndRateAggregator_v2} from "src/price/HarborSingleFeedAndRateAggregator_v2.sol";
import {HarborDoubleFeedAndRateAggregator_v2} from "src/price/HarborDoubleFeedAndRateAggregator_v2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

/// @title Oracle Comparison Base
/// @notice Abstract base for comparing base oracle against candidate implementation
/// @dev Forks mainnet at deployment block, deploys candidate, compares at evenly spaced intervals
/// @dev Subclasses must implement _deployBase(), _deployCandidate(), and _oracleName()
abstract contract OracleComparisonBase is Test {
    // Start block is deployment block
    uint256 constant START_BLOCK = DeployedAddresses.DEPLOYMENT_BLOCK;

    // End block captured at setUp time (latest mainnet block)
    uint256 endTimestamp;
    uint256 endBlock;

    // Implementations - deployed once per test after initial rollFork
    HarborSingleFeedAndRateAggregator_v2 singleImpl;
    HarborDoubleFeedAndRateAggregator_v2 doubleImpl;

    /*//////////////////////////////////////////////////////////////
                         VIRTUAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Deploy the base oracle (e.g., deployed mainnet oracle)
    function _deployBase() internal virtual returns (IWrappedPriceOracle);

    /// @notice Deploy the candidate oracle being evaluated against base
    function _deployCandidate() internal virtual returns (IWrappedPriceOracle);

    /// @notice Display name for logging
    function _oracleName() internal pure virtual returns (string memory);

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

        return
            string.concat(
                vm.toString(y),
                "-",
                m < 10 ? "0" : "",
                vm.toString(m),
                "-",
                d < 10 ? "0" : "",
                vm.toString(d),
                " ",
                h < 10 ? "0" : "",
                vm.toString(h),
                ":",
                min < 10 ? "0" : "",
                vm.toString(min),
                ":",
                s < 10 ? "0" : "",
                vm.toString(s),
                " UTC"
            );
    }

    /// @notice Format block info as "block# (YYYY-MM-DD HH:MM:SS UTC)"
    function _formatBlock(uint256 blockNum, uint256 timestamp) internal pure returns (string memory) {
        return string.concat(vm.toString(blockNum), " (", _formatTimestamp(timestamp), ")");
    }

    /*//////////////////////////////////////////////////////////////
                            SETUP
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual {
        // Fork mainnet at latest to capture endBlock
        vm.createSelectFork("mainnet");
        endBlock = block.number;
        endTimestamp = block.timestamp;
    }

    /// @notice Deploy implementations at the current block
    /// @dev Must be called after rollFork to START_BLOCK
    function _deployImplementations() internal {
        singleImpl = new HarborSingleFeedAndRateAggregator_v2(
            MainnetAddresses.WSTETH,
            MainnetAddresses.FXSAVE,
            MainnetAddresses.SUSDE_USDE_FEED,
            MainnetAddresses.WSTETH_STETH_FEED
        );
        doubleImpl = new HarborDoubleFeedAndRateAggregator_v2(
            MainnetAddresses.WSTETH,
            MainnetAddresses.FXSAVE,
            MainnetAddresses.SUSDE_USDE_FEED,
            MainnetAddresses.WSTETH_STETH_FEED
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
                MainnetAddresses.MAX_AGE,
                MainnetAddresses.MAX_DEV,
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
                MainnetAddresses.MAX_AGE,
                MainnetAddresses.MAX_DEV,
                MainnetAddresses.MAX_AGE,
                MainnetAddresses.MAX_DEV,
                invertPrice
            )
        );

        ERC1967Proxy proxy = new ERC1967Proxy(address(doubleImpl), initData);
        return IWrappedPriceOracle(address(proxy));
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
            (uint256 bMinPrice, uint256 bMaxPrice, uint256 bMinRate, uint256 bMaxRate) = base.latestAnswer();
            (uint256 cMinPrice, uint256 cMaxPrice, uint256 cMinRate, uint256 cMaxRate) = candidate.latestAnswer();

            bool match_ = (bMinPrice == cMinPrice) &&
                (bMaxPrice == cMaxPrice) &&
                (bMinRate == cMinRate) &&
                (bMaxRate == cMaxRate);

            if (!match_) {
                mismatches++;
                console.log("  Block %s: MISMATCH", _formatBlock(block.number, block.timestamp));
                console.log("    base:      minPrice=%d, maxPrice=%d", bMinPrice, bMaxPrice);
                console.log("    base:      minRate=%d, maxRate=%d", bMinRate, bMaxRate);
                console.log("    candidate: minPrice=%d, maxPrice=%d", cMinPrice, cMaxPrice);
                console.log("    candidate: minRate=%d, maxRate=%d", cMinRate, cMaxRate);
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
        assertEq(mismatches, 0, string.concat(name, ": found mismatches"));
    }

    /*//////////////////////////////////////////////////////////////
                            TEST FUNCTION
    //////////////////////////////////////////////////////////////*/

    /// @notice Run the comparison test
    function test_compare() public {
        _prepareForComparison();
        IWrappedPriceOracle base = _deployBase();
        IWrappedPriceOracle candidate = _deployCandidate();
        _compareOracle(base, candidate, _oracleName());
    }
}
