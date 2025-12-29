// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {ChainlinkFeedLib} from "../../src/price/feeds/ChainlinkFeedLib.sol";
import {ArbitrumOracleAddresses} from "../../src/price/ArbitrumOracleAddresses.sol";

contract GetMAG7IndexPriceTest is Test {
    function test_GetMAG7Sum() public view {
        AggregatorV3Interface aapl = AggregatorV3Interface(ArbitrumOracleAddresses.AAPL_USD_FEED);
        AggregatorV3Interface msft = AggregatorV3Interface(ArbitrumOracleAddresses.MSFT_USD_FEED);
        AggregatorV3Interface tsla = AggregatorV3Interface(ArbitrumOracleAddresses.TSLA_USD_FEED);
        AggregatorV3Interface googl = AggregatorV3Interface(ArbitrumOracleAddresses.GOOGL_USD_FEED);
        AggregatorV3Interface meta = AggregatorV3Interface(ArbitrumOracleAddresses.META_USD_FEED);
        AggregatorV3Interface amzn = AggregatorV3Interface(ArbitrumOracleAddresses.AMZN_USD_FEED);
        AggregatorV3Interface nvda = AggregatorV3Interface(ArbitrumOracleAddresses.NVDA_USD_FEED);

        uint256 aaplPrice = ChainlinkFeedLib.latestAnswerNormalized(aapl, aapl.decimals());
        uint256 msftPrice = ChainlinkFeedLib.latestAnswerNormalized(msft, msft.decimals());
        uint256 tslaPrice = ChainlinkFeedLib.latestAnswerNormalized(tsla, tsla.decimals());
        uint256 googlPrice = ChainlinkFeedLib.latestAnswerNormalized(googl, googl.decimals());
        uint256 metaPrice = ChainlinkFeedLib.latestAnswerNormalized(meta, meta.decimals());
        uint256 amznPrice = ChainlinkFeedLib.latestAnswerNormalized(amzn, amzn.decimals());
        uint256 nvdaPrice = ChainlinkFeedLib.latestAnswerNormalized(nvda, nvda.decimals());

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

