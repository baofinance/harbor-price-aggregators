// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ArbitrumConstants} from "@harbor-price/oracles/arbitrum/constants/ArbitrumConstants.sol";
import {SUSDE_USDE} from "@harbor-price/feeds/chainlink/arbitrum/SUSDE_USDE.sol";
import {USDE_USD} from "@harbor-price/feeds/chainlink/arbitrum/USDE_USD.sol";
import {AAPL_USD} from "@harbor-price/feeds/chainlink/arbitrum/AAPL_USD.sol";
import {MSFT_USD} from "@harbor-price/feeds/chainlink/arbitrum/MSFT_USD.sol";
import {TSLA_USD} from "@harbor-price/feeds/chainlink/arbitrum/TSLA_USD.sol";
import {GOOGL_USD} from "@harbor-price/feeds/chainlink/arbitrum/GOOGL_USD.sol";
import {META_USD} from "@harbor-price/feeds/chainlink/arbitrum/META_USD.sol";
import {AMZN_USD} from "@harbor-price/feeds/chainlink/arbitrum/AMZN_USD.sol";
import {NVDA_USD} from "@harbor-price/feeds/chainlink/arbitrum/NVDA_USD.sol";
import {Aggregator_USDE_MAG7i26} from "@harbor-price/oracles/arbitrum/Aggregator_USDE_MAG7i26.sol";

/// @notice Arbitrum USDE/MAG7.i26 oracle.
/// @dev Hard-coded wiring for Arbitrum; deploy scripts select this bytecode by chain.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_USDE_MAG7i26_arbitrum is Aggregator_USDE_MAG7i26 {
    constructor()
        Aggregator_USDE_MAG7i26(
            SUSDE_USDE.FEED, // Rate feed (sUSDE/USDE)
            USDE_USD.FEED, // Base USD feed
            USDE_USD.HEARTBEAT, // Base USD feed heartbeat
            ArbitrumConstants.MAG7_I26_INDEX_PRICE, // Index price
            [
                Aggregator_USDE_MAG7i26.FeedConfig({feed: AAPL_USD.FEED, heartbeat: AAPL_USD.HEARTBEAT}),
                Aggregator_USDE_MAG7i26.FeedConfig({feed: MSFT_USD.FEED, heartbeat: MSFT_USD.HEARTBEAT}),
                Aggregator_USDE_MAG7i26.FeedConfig({feed: TSLA_USD.FEED, heartbeat: TSLA_USD.HEARTBEAT}),
                Aggregator_USDE_MAG7i26.FeedConfig({feed: GOOGL_USD.FEED, heartbeat: GOOGL_USD.HEARTBEAT}),
                Aggregator_USDE_MAG7i26.FeedConfig({feed: META_USD.FEED, heartbeat: META_USD.HEARTBEAT}),
                Aggregator_USDE_MAG7i26.FeedConfig({feed: AMZN_USD.FEED, heartbeat: AMZN_USD.HEARTBEAT}),
                Aggregator_USDE_MAG7i26.FeedConfig({feed: NVDA_USD.FEED, heartbeat: NVDA_USD.HEARTBEAT})
            ]
        )
    {}
}
