// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {BTC_USD} from "@harbor-price/feeds/chainlink/mainnet/BTC_USD.sol";
import {Aggregator_hsstETH_BTC_USD} from "@harbor-price/aggregators/mainnet/Aggregator_hsstETH_BTC_USD.sol";

/// @notice Ethereum mainnet hsstETH-BTC/USD oracle.
/// @dev Price in USD = rate × BTC/USD (reference asset is BTC, not stETH).
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_hsstETH_BTC_USD_mainnet is Aggregator_hsstETH_BTC_USD {
    constructor()
        Aggregator_hsstETH_BTC_USD(
            MainnetRateSources.MINTER_HSSTETH_BTC,
            BTC_USD.FEED,
            BTC_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
