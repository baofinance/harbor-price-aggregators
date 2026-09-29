// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {console} from "forge-std/Test.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {ChainlinkFeedLib} from "@harbor-price/feeds/chainlink/ChainlinkFeedLib.sol";
import {RobinhoodForkTest} from "@harbor-price-test/fork/RobinhoodForkTest.sol";
import {RobinhoodUsdFeedSpecs} from "@harbor-price-test/feeds/robinhood/RobinhoodUsdFeedSpecs.sol";

/// @notice Live Robinhood Chainlink USD feeds: documented proxy, code on chain, fresh, strictly positive.
/// @dev `forge test --match-path test/robinhood/RobinhoodUsdFeedsFork.t.sol -vv`
///      `ROBINHOOD_RPC_URL` must be set (foundry.toml alias `robinhood`). Unset fails, it does not skip.
contract RobinhoodUsdFeedsForkTest is RobinhoodForkTest {
    function test_fork_eachUsdFeedIsFreshAndPositive() public view {
        RobinhoodUsdFeedSpecs.FeedSpec[] memory specs = RobinhoodUsdFeedSpecs.specs();
        for (uint256 i; i < specs.length; ++i) {
            address feed = specs[i].feed;
            assertTrue(feed.code.length > 0, specs[i].ticker);

            AggregatorV3Interface agg = AggregatorV3Interface(feed);
            uint256 price = ChainlinkFeedLib.latestAnswerNormalized(agg, agg.decimals(), specs[i].heartbeat);

            console.log("===", specs[i].ticker, "/USD ===");
            console.log("feed:", feed);
            console.log("price 18 decimals:", price);
            console.log("USD whole:", price / 1e18);
            console.log("USD 18dp remainder:", price % 1e18);
            console.log("");

            assertGt(price, 0, specs[i].ticker);
        }
    }
}
