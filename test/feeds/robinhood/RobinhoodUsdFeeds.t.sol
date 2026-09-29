// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {RobinhoodUsdFeedSpecs} from "@harbor-price-test/feeds/robinhood/RobinhoodUsdFeedSpecs.sol";

/// @notice Constants for every Robinhood tokenized-equity USD feed library.
/// @dev Addresses match doc/robinhood-chainlink-usd-feeds.md (standard proxies).
///      Live `latestAnswer` is `test/robinhood/RobinhoodUsdFeedsFork.t.sol` — this suite does not mock feeds.
contract RobinhoodUsdFeedsTest is Test {
    uint256 internal constant EXPECTED_HEARTBEAT = 86400;

    function test_eachFeedMatchesDocumentedProxyAndHeartbeat() public pure {
        RobinhoodUsdFeedSpecs.FeedSpec[] memory specs = RobinhoodUsdFeedSpecs.specs();
        for (uint256 i; i < specs.length; ++i) {
            _assertFeed(specs[i].ticker, specs[i].feed, specs[i].heartbeat, specs[i].expected);
        }
    }

    function test_feedAddressesAreUnique() public pure {
        RobinhoodUsdFeedSpecs.FeedSpec[] memory specs = RobinhoodUsdFeedSpecs.specs();
        for (uint256 a; a < specs.length; ++a) {
            for (uint256 b = a + 1; b < specs.length; ++b) {
                assertTrue(specs[a].feed != specs[b].feed, "duplicate FEED address");
            }
        }
    }

    function _assertFeed(string memory ticker, address feed, uint256 heartbeat, address expected) private pure {
        assertTrue(feed != address(0), string.concat(ticker, " FEED is zero"));
        assertEq(feed, expected, string.concat(ticker, " FEED"));
        assertEq(heartbeat, EXPECTED_HEARTBEAT, string.concat(ticker, " HEARTBEAT"));
    }
}
