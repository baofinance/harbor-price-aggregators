// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {BaseMultiFeedNormalizedAggregatorTestBase} from "./BaseMultiFeedNormalizedAggregatorTestBase.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";
import {Aggregator_stETH_BOM5} from "@harbor-price/oracles/base/Aggregator_stETH_BOM5.sol";

contract Aggregator_stETH_BOM5_Test is BaseMultiFeedNormalizedAggregatorTestBase {
    function _contractName() internal pure override returns (string memory) {
        return type(Aggregator_stETH_BOM5).name;
    }

    function _createAggregator(
        string memory baseName,
        address rateFeed,
        address baseUsdFeed,
        uint256 baseUsdFeedHeartbeat,
        address[5] memory feeds,
        uint256[5] memory feedHeartbeats,
        uint256[5] memory normFactors
    ) internal override returns (IHarborPriceAggregatorV3) {
        Aggregator_stETH_BOM5.FeedConfig[5] memory feedConfigs;
        for (uint256 i = 0; i < 5; i++) {
            feedConfigs[i] = Aggregator_stETH_BOM5.FeedConfig({
                feed: feeds[i],
                heartbeat: feedHeartbeats[i],
                normFactor: normFactors[i]
            });
        }

        return
            IHarborPriceAggregatorV3(
                address(new Aggregator_stETH_BOM5(baseName, rateFeed, baseUsdFeed, baseUsdFeedHeartbeat, feedConfigs))
            );
    }

    function _createWithZeroRateFeed() internal override {
        address[5] memory feedAddrs;
        uint256[5] memory feedHeartbeats_;
        uint256[5] memory normFactors_;
        for (uint256 i = 0; i < 5; i++) {
            feedAddrs[i] = address(mockFeeds[i]);
            feedHeartbeats_[i] = DEFAULT_HEARTBEAT;
            if (i == 0) normFactors_[i] = NORM_FACTOR_0;
            else if (i == 1) normFactors_[i] = NORM_FACTOR_1;
            else if (i == 2) normFactors_[i] = NORM_FACTOR_2;
            else if (i == 3) normFactors_[i] = NORM_FACTOR_3;
            else if (i == 4) normFactors_[i] = NORM_FACTOR_4;
        }

        Aggregator_stETH_BOM5.FeedConfig[5] memory feedConfigs;
        for (uint256 i = 0; i < 5; i++) {
            feedConfigs[i] = Aggregator_stETH_BOM5.FeedConfig({
                feed: feedAddrs[i],
                heartbeat: feedHeartbeats_[i],
                normFactor: normFactors_[i]
            });
        }

        new Aggregator_stETH_BOM5(
            _expectedBaseName(),
            address(0),
            address(mockBaseUsdFeed),
            DEFAULT_HEARTBEAT,
            feedConfigs
        );
    }

    function _createWithZeroBaseUsdFeed() internal override {
        address[5] memory feedAddrs;
        uint256[5] memory feedHeartbeats_;
        uint256[5] memory normFactors_;
        for (uint256 i = 0; i < 5; i++) {
            feedAddrs[i] = address(mockFeeds[i]);
            feedHeartbeats_[i] = DEFAULT_HEARTBEAT;
            if (i == 0) normFactors_[i] = NORM_FACTOR_0;
            else if (i == 1) normFactors_[i] = NORM_FACTOR_1;
            else if (i == 2) normFactors_[i] = NORM_FACTOR_2;
            else if (i == 3) normFactors_[i] = NORM_FACTOR_3;
            else if (i == 4) normFactors_[i] = NORM_FACTOR_4;
        }

        Aggregator_stETH_BOM5.FeedConfig[5] memory feedConfigs;
        for (uint256 i = 0; i < 5; i++) {
            feedConfigs[i] = Aggregator_stETH_BOM5.FeedConfig({
                feed: feedAddrs[i],
                heartbeat: feedHeartbeats_[i],
                normFactor: normFactors_[i]
            });
        }

        new Aggregator_stETH_BOM5(
            _expectedBaseName(),
            address(mockRateFeed),
            address(0),
            DEFAULT_HEARTBEAT,
            feedConfigs
        );
    }

    function _createWithZeroFeed(uint256 feedIndex) internal override {
        address[5] memory feedAddrs;
        uint256[5] memory feedHeartbeats_;
        uint256[5] memory normFactors_;
        for (uint256 i = 0; i < 5; i++) {
            if (i == feedIndex) {
                feedAddrs[i] = address(0);
            } else {
                feedAddrs[i] = address(mockFeeds[i]);
            }
            feedHeartbeats_[i] = DEFAULT_HEARTBEAT;
            if (i == 0) normFactors_[i] = NORM_FACTOR_0;
            else if (i == 1) normFactors_[i] = NORM_FACTOR_1;
            else if (i == 2) normFactors_[i] = NORM_FACTOR_2;
            else if (i == 3) normFactors_[i] = NORM_FACTOR_3;
            else if (i == 4) normFactors_[i] = NORM_FACTOR_4;
        }

        Aggregator_stETH_BOM5.FeedConfig[5] memory feedConfigs;
        for (uint256 i = 0; i < 5; i++) {
            feedConfigs[i] = Aggregator_stETH_BOM5.FeedConfig({
                feed: feedAddrs[i],
                heartbeat: feedHeartbeats_[i],
                normFactor: normFactors_[i]
            });
        }

        new Aggregator_stETH_BOM5(
            _expectedBaseName(),
            address(mockRateFeed),
            address(mockBaseUsdFeed),
            DEFAULT_HEARTBEAT,
            feedConfigs
        );
    }

    function _createWithZeroNormFactor(uint256 normIndex) internal override {
        address[5] memory feedAddrs;
        uint256[5] memory feedHeartbeats_;
        uint256[5] memory normFactors_;
        for (uint256 i = 0; i < 5; i++) {
            feedAddrs[i] = address(mockFeeds[i]);
            feedHeartbeats_[i] = DEFAULT_HEARTBEAT;
            if (i == normIndex) {
                normFactors_[i] = 0;
            } else {
                if (i == 0) normFactors_[i] = NORM_FACTOR_0;
                else if (i == 1) normFactors_[i] = NORM_FACTOR_1;
                else if (i == 2) normFactors_[i] = NORM_FACTOR_2;
                else if (i == 3) normFactors_[i] = NORM_FACTOR_3;
                else if (i == 4) normFactors_[i] = NORM_FACTOR_4;
            }
        }

        Aggregator_stETH_BOM5.FeedConfig[5] memory feedConfigs;
        for (uint256 i = 0; i < 5; i++) {
            feedConfigs[i] = Aggregator_stETH_BOM5.FeedConfig({
                feed: feedAddrs[i],
                heartbeat: feedHeartbeats_[i],
                normFactor: normFactors_[i]
            });
        }

        new Aggregator_stETH_BOM5(
            _expectedBaseName(),
            address(mockRateFeed),
            address(mockBaseUsdFeed),
            DEFAULT_HEARTBEAT,
            feedConfigs
        );
    }
}
