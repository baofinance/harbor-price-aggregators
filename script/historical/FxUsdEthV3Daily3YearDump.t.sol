// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {HarborAggregator_v3} from "@harbor-price/HarborAggregator_v3.sol";
import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {ETH_USD} from "@harbor-price/feeds/chainlink/mainnet/ETH_USD.sol";
import {Aggregator_fxUSD_ETH} from "@harbor-price/oracles/Aggregator_fxUSD_ETH.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {LatestAnswerErrorClassifier} from "./LatestAnswerErrorClassifier.sol";
import {UtcTimestampFormatter} from "@harbor-price/format/UtcTimestampFormatter.sol";

/// @title fxUSD/ETH v3 Daily 3-Year Dump
/// @notice Deploys a fresh v3 fxUSD/ETH oracle and samples daily for ~3 years on a deterministic mainnet fork.
contract FxUsdEthV3Daily3YearDump is Test {
    // Deterministic end block (UTC 2025-12-22 11:32:47). Keep in sync with other forked harnesses if desired.
    uint256 constant END_BLOCK = 24_067_873;

    // Approximate blocks/day on Ethereum (~12s blocks).
    uint256 constant BLOCKS_PER_DAY = 7_200;
    uint256 constant DAYS = 365 * 1;

    // Adaptive sampling settings.
    uint256 constant COARSE_STEP_DAYS = 5;
    // Fixed-point scale for normalized moves where 1e18 == 1.0 == 100%.
    uint256 constant WAD = 1e18;
    // If the estimated per-day move between two sampled points exceeds this, refine the interval.
    // Units: normalized WAD per day.
    int256 constant REFINE_THRESHOLD_WAD = 1e16; // 1% per day
    // If a 1-day move exceeds this, do intraday sampling (hourly) and emit move24hAbs.
    // Keep this high: intraday sampling is expensive on a fork.
    int256 constant INTRADAY_THRESHOLD_WAD = 5e16; // 5%
    uint256 constant BLOCKS_PER_HOUR = 300;

    /// @dev Sample data struct to reduce stack depth
    struct SampleData {
        uint256 sampleBlock;
        uint256 ts;
        bool stop;
        bool hasData;
        uint256 minPrice;
        uint256 maxPrice;
        uint256 minRate;
        uint256 maxRate;
        string err;
        uint256 mid;
    }

    uint256 _prevDaysAgo;
    uint256 _prevMid;
    bool _hasPrev;

    function _abs(int256 x) private pure returns (int256) {
        return x < 0 ? -x : x;
    }

    function _estimateDailyMoveWad(uint256 mid, uint256 daysAgo) private view returns (int256 moveWad) {
        if (!_hasPrev) return 0;
        if (_prevMid == 0) return 0;
        uint256 deltaDays = daysAgo - _prevDaysAgo;
        if (deltaDays == 0) return 0;

        // Signed normalized move over the whole interval.
        int256 ratioWad = int256((mid * WAD) / _prevMid) - int256(WAD);
        // Dailyized signed move per day.
        return ratioWad / int256(deltaDays);
    }

    function _maxAbsMove24hWad(
        address oracle,
        uint256 startDaysAgo,
        uint256 endDaysAgo,
        uint256 startMid
    ) private returns (uint256 maxAbsWad) {
        if (startMid == 0) return 0;
        if (endDaysAgo != startDaysAgo + 1) return 0;

        uint256 startBlock = END_BLOCK - (startDaysAgo * BLOCKS_PER_DAY);
        uint256 endBlock = END_BLOCK - (endDaysAgo * BLOCKS_PER_DAY);
        if (endBlock > startBlock) return 0;

        uint256 currentBlock = startBlock;
        while (currentBlock >= endBlock) {
            vm.rollFork(currentBlock);

            (bool stop, bool hasData, uint256 minPrice, uint256 maxPrice, , , ) = LatestAnswerErrorClassifier
                .tryLatestAnswer(oracle);
            if (stop || !hasData) return 0;

            uint256 mid = (minPrice + maxPrice) / 2;
            int256 moveWad = int256((mid * WAD) / startMid) - int256(WAD);
            uint256 absWad = uint256(_abs(moveWad));
            if (absWad > maxAbsWad) maxAbsWad = absWad;

            if (currentBlock < BLOCKS_PER_HOUR) break;
            if (currentBlock - BLOCKS_PER_HOUR < endBlock) break;
            currentBlock -= BLOCKS_PER_HOUR;
        }
    }

    function _sample(address oracle, uint256 daysAgo) private returns (SampleData memory s) {
        s.sampleBlock = END_BLOCK - (daysAgo * BLOCKS_PER_DAY);
        vm.rollFork(s.sampleBlock);
        s.ts = block.timestamp;

        (s.stop, s.hasData, s.minPrice, s.maxPrice, s.minRate, s.maxRate, s.err) = LatestAnswerErrorClassifier
            .tryLatestAnswer(oracle);

        if (s.hasData) {
            s.mid = (s.minPrice + s.maxPrice) / 2;
        }
    }

    function _writeSample(address oracle, string memory filename, SampleData memory s, uint256 daysAgo) private {
        string memory timeStr = UtcTimestampFormatter.format(s.ts);
        string memory prefix = string.concat(vm.toString(s.sampleBlock), ",", vm.toString(s.ts), ",", timeStr, ",");

        int256 moveWad = 0;
        uint256 move24hAbsWad = 0;
        if (s.hasData) {
            moveWad = _estimateDailyMoveWad(s.mid, daysAgo);
            if (_hasPrev && (daysAgo == _prevDaysAgo + 1) && (_abs(moveWad) > INTRADAY_THRESHOLD_WAD)) {
                move24hAbsWad = _maxAbsMove24hWad(oracle, _prevDaysAgo, daysAgo, _prevMid);
            }
            vm.writeLine(
                filename,
                string.concat(
                    prefix,
                    vm.toString(s.minPrice),
                    ",",
                    vm.toString(s.maxPrice),
                    ",",
                    vm.toString(s.minRate),
                    ",",
                    vm.toString(s.maxRate),
                    ",",
                    vm.toString(moveWad),
                    ",",
                    vm.toString(move24hAbsWad),
                    ",",
                    s.err
                )
            );

            _prevDaysAgo = daysAgo;
            _prevMid = s.mid;
            _hasPrev = true;
        } else {
            vm.writeLine(
                filename,
                string.concat(prefix, "0,0,0,0,", vm.toString(moveWad), ",", vm.toString(move24hAbsWad), ",", s.err)
            );
        }
    }

    function _emitInterval(address oracle, string memory filename, uint256 endDaysAgo) private returns (bool stop) {
        uint256 startDaysAgo = _prevDaysAgo;
        if (!_hasPrev || endDaysAgo <= startDaysAgo) revert("bad interval");

        SampleData memory s = _sample(oracle, endDaysAgo);

        if (s.stop || !s.hasData) {
            s.hasData = false;
            _writeSample(oracle, filename, s, endDaysAgo);
            return true;
        }

        uint256 deltaDays = endDaysAgo - startDaysAgo;
        int256 dailyMoveWad = _estimateDailyMoveWad(s.mid, endDaysAgo);

        if (deltaDays == 1 || _abs(dailyMoveWad) <= REFINE_THRESHOLD_WAD) {
            _writeSample(oracle, filename, s, endDaysAgo);
            return false;
        }

        uint256 midDaysAgo = (startDaysAgo + endDaysAgo) / 2;
        if (midDaysAgo == startDaysAgo) midDaysAgo = startDaysAgo + 1;

        if (_emitInterval(oracle, filename, midDaysAgo)) return true;
        return _emitInterval(oracle, filename, endDaysAgo);
    }

    function test_dump_fxusd_eth_v3_daily_3y() public {
        vm.createSelectFork("mainnet", END_BLOCK);

        // Deploy a fresh v3 implementation + proxy (do not use already-deployed proxies).
        Aggregator_fxUSD_ETH impl = new Aggregator_fxUSD_ETH(
            MainnetRateSources.FXSAVE,
            ETH_USD.FEED,
            ETH_USD.HEARTBEAT,
            1,
            true
        );

        // BaoFixedOwnable has no initialize - owner is set via constructor immutables
        ERC1967Proxy proxy = new ERC1967Proxy(address(impl), "");
        IWrappedPriceOracle oracle = IWrappedPriceOracle(address(proxy));

        string memory filename = "results/FXUSD_ETH_v3_daily_3y.csv";
        vm.writeFile(filename, "block,timestamp,time,minPrice,maxPrice,minRate,maxRate,move,move24hAbs,error\n");

        _hasPrev = false;
        _prevDaysAgo = 0;
        _prevMid = 0;

        {
            SampleData memory s = _sample(address(oracle), 0);
            _writeSample(address(oracle), filename, s, 0);
            if (s.stop || !s.hasData) return;
        }

        for (uint256 daysAgo = COARSE_STEP_DAYS; daysAgo <= DAYS; daysAgo += COARSE_STEP_DAYS) {
            if (_emitInterval(address(oracle), filename, daysAgo)) break;
        }
    }
}
