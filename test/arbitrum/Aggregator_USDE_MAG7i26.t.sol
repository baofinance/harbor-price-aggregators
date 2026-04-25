// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ArbitrumMultiFeedIndexAggregatorTestBase} from "@harbor-test/arbitrum/ArbitrumMultiFeedIndexAggregatorTestBase.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";
import {Aggregator_USDE_MAG7i26} from "@harbor-price/aggregators/arbitrum/Aggregator_USDE_MAG7i26.sol";

contract Aggregator_USDE_MAG7i26_Test is ArbitrumMultiFeedIndexAggregatorTestBase {
    function _contractName() internal pure override returns (string memory) {
        return type(Aggregator_USDE_MAG7i26).name;
    }

    function _createAggregator(
        address rateFeed,
        address baseUsdFeed,
        uint256 baseUsdFeedHeartbeat,
        uint256 indexPrice,
        address[7] memory feeds,
        uint256[7] memory feedHeartbeats
    ) internal override returns (IHarborPriceAggregatorV3) {
        Aggregator_USDE_MAG7i26.FeedConfig[7] memory feedConfigs;
        for (uint256 i = 0; i < 7; i++) {
            feedConfigs[i] = Aggregator_USDE_MAG7i26.FeedConfig({feed: feeds[i], heartbeat: feedHeartbeats[i]});
        }

        return
            IHarborPriceAggregatorV3(
                address(
                    new Aggregator_USDE_MAG7i26(rateFeed, baseUsdFeed, baseUsdFeedHeartbeat, indexPrice, feedConfigs)
                )
            );
    }

    function _createWithZeroRateFeed() internal override {
        address[7] memory feedAddrs;
        uint256[7] memory feedHeartbeats_;
        for (uint256 i = 0; i < 7; i++) {
            feedAddrs[i] = address(mockFeeds[i]);
            feedHeartbeats_[i] = DEFAULT_HEARTBEAT;
        }

        Aggregator_USDE_MAG7i26.FeedConfig[7] memory feedConfigs;
        for (uint256 i = 0; i < 7; i++) {
            feedConfigs[i] = Aggregator_USDE_MAG7i26.FeedConfig({feed: feedAddrs[i], heartbeat: feedHeartbeats_[i]});
        }

        new Aggregator_USDE_MAG7i26(address(0), address(mockBaseUsdFeed), DEFAULT_HEARTBEAT, INDEX_PRICE, feedConfigs);
    }

    function _createWithZeroBaseUsdFeed() internal override {
        address[7] memory feedAddrs;
        uint256[7] memory feedHeartbeats_;
        for (uint256 i = 0; i < 7; i++) {
            feedAddrs[i] = address(mockFeeds[i]);
            feedHeartbeats_[i] = DEFAULT_HEARTBEAT;
        }

        Aggregator_USDE_MAG7i26.FeedConfig[7] memory feedConfigs;
        for (uint256 i = 0; i < 7; i++) {
            feedConfigs[i] = Aggregator_USDE_MAG7i26.FeedConfig({feed: feedAddrs[i], heartbeat: feedHeartbeats_[i]});
        }

        new Aggregator_USDE_MAG7i26(address(mockRateFeed), address(0), DEFAULT_HEARTBEAT, INDEX_PRICE, feedConfigs);
    }

    function _createWithZeroIndexPrice() internal override {
        address[7] memory feedAddrs;
        uint256[7] memory feedHeartbeats_;
        for (uint256 i = 0; i < 7; i++) {
            feedAddrs[i] = address(mockFeeds[i]);
            feedHeartbeats_[i] = DEFAULT_HEARTBEAT;
        }

        Aggregator_USDE_MAG7i26.FeedConfig[7] memory feedConfigs;
        for (uint256 i = 0; i < 7; i++) {
            feedConfigs[i] = Aggregator_USDE_MAG7i26.FeedConfig({feed: feedAddrs[i], heartbeat: feedHeartbeats_[i]});
        }

        new Aggregator_USDE_MAG7i26(address(mockRateFeed), address(mockBaseUsdFeed), DEFAULT_HEARTBEAT, 0, feedConfigs);
    }

    function _createWithZeroFeed(uint256 feedIndex) internal override {
        address[7] memory feedAddrs;
        uint256[7] memory feedHeartbeats_;
        for (uint256 i = 0; i < 7; i++) {
            if (i == feedIndex) {
                feedAddrs[i] = address(0);
            } else {
                feedAddrs[i] = address(mockFeeds[i]);
            }
            feedHeartbeats_[i] = DEFAULT_HEARTBEAT;
        }

        Aggregator_USDE_MAG7i26.FeedConfig[7] memory feedConfigs;
        for (uint256 i = 0; i < 7; i++) {
            feedConfigs[i] = Aggregator_USDE_MAG7i26.FeedConfig({feed: feedAddrs[i], heartbeat: feedHeartbeats_[i]});
        }

        new Aggregator_USDE_MAG7i26(
            address(mockRateFeed),
            address(mockBaseUsdFeed),
            DEFAULT_HEARTBEAT,
            INDEX_PRICE,
            feedConfigs
        );
    }
}
