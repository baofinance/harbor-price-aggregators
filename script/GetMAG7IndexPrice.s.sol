// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {ChainlinkFeedLib} from "@harbor-price/feeds/chainlink/ChainlinkFeedLib.sol";
import {AAPL_USD} from "@harbor-price/feeds/chainlink/arbitrum/AAPL_USD.sol";
import {MSFT_USD} from "@harbor-price/feeds/chainlink/arbitrum/MSFT_USD.sol";
import {TSLA_USD} from "@harbor-price/feeds/chainlink/arbitrum/TSLA_USD.sol";
import {GOOGL_USD} from "@harbor-price/feeds/chainlink/arbitrum/GOOGL_USD.sol";
import {META_USD} from "@harbor-price/feeds/chainlink/arbitrum/META_USD.sol";
import {AMZN_USD} from "@harbor-price/feeds/chainlink/arbitrum/AMZN_USD.sol";
import {NVDA_USD} from "@harbor-price/feeds/chainlink/arbitrum/NVDA_USD.sol";

/// @notice Utility script to calculate MAG7 index price (sum of 7 stock feeds)
/// @dev Run with: forge script script/GetMAG7IndexPrice.s.sol:GetMAG7IndexPrice --rpc-url $arbitrum -vvv
contract GetMAG7IndexPrice is Script {
    function run() public view {
        AggregatorV3Interface aapl = AggregatorV3Interface(AAPL_USD.FEED);
        AggregatorV3Interface msft = AggregatorV3Interface(MSFT_USD.FEED);
        AggregatorV3Interface tsla = AggregatorV3Interface(TSLA_USD.FEED);
        AggregatorV3Interface googl = AggregatorV3Interface(GOOGL_USD.FEED);
        AggregatorV3Interface meta = AggregatorV3Interface(META_USD.FEED);
        AggregatorV3Interface amzn = AggregatorV3Interface(AMZN_USD.FEED);
        AggregatorV3Interface nvda = AggregatorV3Interface(NVDA_USD.FEED);

        uint256 aaplPrice = ChainlinkFeedLib.latestAnswerNormalized(aapl, aapl.decimals(), AAPL_USD.HEARTBEAT);
        uint256 msftPrice = ChainlinkFeedLib.latestAnswerNormalized(msft, msft.decimals(), MSFT_USD.HEARTBEAT);
        uint256 tslaPrice = ChainlinkFeedLib.latestAnswerNormalized(tsla, tsla.decimals(), TSLA_USD.HEARTBEAT);
        uint256 googlPrice = ChainlinkFeedLib.latestAnswerNormalized(googl, googl.decimals(), GOOGL_USD.HEARTBEAT);
        uint256 metaPrice = ChainlinkFeedLib.latestAnswerNormalized(meta, meta.decimals(), META_USD.HEARTBEAT);
        uint256 amznPrice = ChainlinkFeedLib.latestAnswerNormalized(amzn, amzn.decimals(), AMZN_USD.HEARTBEAT);
        uint256 nvdaPrice = ChainlinkFeedLib.latestAnswerNormalized(nvda, nvda.decimals(), NVDA_USD.HEARTBEAT);

        uint256 sum = aaplPrice + msftPrice + tslaPrice + googlPrice + metaPrice + amznPrice + nvdaPrice;

        console.log("AAPL:", aaplPrice);
        console.log("MSFT:", msftPrice);
        console.log("TSLA:", tslaPrice);
        console.log("GOOGL:", googlPrice);
        console.log("META:", metaPrice);
        console.log("AMZN:", amznPrice);
        console.log("NVDA:", nvdaPrice);
        console.log("SUM (18 decimals):", sum);
        console.log("SUM (human readable):", sum / 1e18);
    }
}

