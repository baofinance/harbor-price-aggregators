// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {MainnetRateSources} from "@harbor-price/rates/mainnet/MainnetRateSources.sol";
import {EUR_USD} from "@harbor-price/feeds/chainlink/mainnet/EUR_USD.sol";
import {Aggregator_hsstETH_EUR_USD} from "@harbor-price/aggregators/mainnet/Aggregator_hsstETH_EUR_USD.sol";

/// @notice Ethereum mainnet hsstETH-EUR/USD oracle.
/// @dev Price in USD = rate × EUR/USD (reference asset is EUR, not stETH).
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_hsstETH_EUR_USD_mainnet is Aggregator_hsstETH_EUR_USD {
    constructor()
        Aggregator_hsstETH_EUR_USD(
            MainnetRateSources.MINTER_HSSTETH_EUR,
            EUR_USD.FEED,
            EUR_USD.HEARTBEAT,
            1,
            false
        )
    {}
}
