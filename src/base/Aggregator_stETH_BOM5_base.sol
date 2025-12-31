// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {BaseConstants} from "@harbor-price/oracles/base/constants/BaseConstants.sol";
import {WSTETH_STETH} from "@harbor-price/feeds/chainlink/base/WSTETH_STETH.sol";
import {STETH_USD} from "@harbor-price/feeds/chainlink/base/STETH_USD.sol";
import {DOGE_USD} from "@harbor-price/feeds/chainlink/base/DOGE_USD.sol";
import {SHIB_USD} from "@harbor-price/feeds/chainlink/base/SHIB_USD.sol";
import {PEPE_USD} from "@harbor-price/feeds/chainlink/base/PEPE_USD.sol";
import {TRUMP_USD} from "@harbor-price/feeds/chainlink/base/TRUMP_USD.sol";
import {WIF_USD} from "@harbor-price/feeds/chainlink/base/WIF_USD.sol";
import {Aggregator_stETH_BOM5} from "@harbor-price/oracles/base/Aggregator_stETH_BOM5.sol";

/// @notice Base stETH/BOM5 oracle.
/// @dev Hard-coded wiring for Base; deploy scripts select this bytecode by chain.
///      BOM5 = Bag of Memes 5 (DOGE, SHIB, PEPE, TRUMP, WIF) with supply normalization.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_stETH_BOM5_base is Aggregator_stETH_BOM5 {
    constructor()
        Aggregator_stETH_BOM5(
            WSTETH_STETH.FEED, // Rate feed
            STETH_USD.FEED,
            STETH_USD.HEARTBEAT, // Base USD feed heartbeat (stETH/USD)
            [
                Aggregator_stETH_BOM5.FeedConfig({
                    feed: DOGE_USD.FEED,
                    heartbeat: DOGE_USD.HEARTBEAT,
                    normFactor: BaseConstants.DOGE_NORM_FACTOR
                }),
                Aggregator_stETH_BOM5.FeedConfig({
                    feed: SHIB_USD.FEED,
                    heartbeat: SHIB_USD.HEARTBEAT,
                    normFactor: BaseConstants.SHIB_NORM_FACTOR
                }),
                Aggregator_stETH_BOM5.FeedConfig({
                    feed: PEPE_USD.FEED,
                    heartbeat: PEPE_USD.HEARTBEAT,
                    normFactor: BaseConstants.PEPE_NORM_FACTOR
                }),
                Aggregator_stETH_BOM5.FeedConfig({
                    feed: TRUMP_USD.FEED,
                    heartbeat: TRUMP_USD.HEARTBEAT,
                    normFactor: BaseConstants.TRUMP_NORM_FACTOR
                }),
                Aggregator_stETH_BOM5.FeedConfig({
                    feed: WIF_USD.FEED,
                    heartbeat: WIF_USD.HEARTBEAT,
                    normFactor: BaseConstants.WIF_NORM_FACTOR
                })
            ]
        )
    {}
}
