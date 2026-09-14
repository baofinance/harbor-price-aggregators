// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetForkTest} from "@harbor-price-test/fork/MainnetForkTest.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";
import {Aggregator_fxUSD_SPCX_mainnet} from "@harbor-price/mainnet/Aggregator_fxUSD_SPCX_mainnet.sol";
import {Aggregator_stETH_SPCX_mainnet} from "@harbor-price/mainnet/Aggregator_stETH_SPCX_mainnet.sol";

/// @notice The weekend outage in SPCX/USD, held still at the block that produced it.
/// @dev Both tests are SKIPPED, and are expected to fail the moment the skip is removed. They are the
///      reproduction for a defect in a DEPLOYED contract, kept executable so the fix can be shown to
///      work rather than argued: remove the `vm.skip` and they must pass.
///
///      SPCX/USD publishes only inside the US equity session - every session opens at exactly 13:30
///      UTC and the last round lands by ~19:57 UTC - and posts nothing at all outside it, unlike
///      STRC/USD and the arbitrum equity feeds, which post a heartbeat round every 24h through the
///      weekend. So its configured `HEARTBEAT = 86400` states a guarantee the feed does not give, and
///      the two deployed SPCX aggregators revert `StaleFeedData` from ~24h after Friday's close until
///      Monday's open: ~41h every weekend, ~65h when the Monday is a holiday.
///
///      Block 25926463 is Mon 07 Sep 2026 15:46 UTC - Labor Day, with the market shut. The feed last
///      posted Fri 04 Sep 19:53 UTC, 67.9 hours earlier.
///
///      Full measurement, reproduction and the recommended fix: `doc/spcx-weekend-staleness.md`.
contract SpcxWeekendOutageForkTest is MainnetForkTest {
    /// @dev Do not repin. The block IS the reproduction; any other block loses the condition.
    function forkBlock() internal pure override returns (uint256) {
        return 25926463;
    }

    IHarborPriceAggregatorV3 internal fxUsdSpcx;
    IHarborPriceAggregatorV3 internal stEthSpcx;

    function setUp() public override {
        super.setUp();
        fxUsdSpcx = IHarborPriceAggregatorV3(address(new Aggregator_fxUSD_SPCX_mainnet()));
        stEthSpcx = IHarborPriceAggregatorV3(address(new Aggregator_stETH_SPCX_mainnet()));
    }

    /// @notice fxUSD/SPCX answers while the US market is shut. Fails until the heartbeat states a
    ///         bound the feed can actually meet.
    function test_fork_fxUSD_SPCX_answersWhileTheMarketIsShut() public {
        vm.skip(true);
        fxUsdSpcx.latestAnswer();
    }

    /// @notice stETH/SPCX answers while the US market is shut. Fails until the heartbeat states a
    ///         bound the feed can actually meet.
    function test_fork_stETH_SPCX_answersWhileTheMarketIsShut() public {
        vm.skip(true);
        stEthSpcx.latestAnswer();
    }
}
