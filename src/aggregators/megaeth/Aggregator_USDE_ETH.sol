// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Aggregator_SingleRate_DoublePrice} from "@harbor-price/aggregators/base/Aggregator_SingleRate_DoublePrice.sol";

/// @notice USDE/ETH oracle (rate: sUSDe/USDe feed, price: (USDE/USD)/(ETH/USD)).
/// @dev This is the formula contract; wiring (feeds/addresses) is provided via constructor.
// solhint-disable-next-line contract-name-capwords
contract Aggregator_USDE_ETH is Aggregator_SingleRate_DoublePrice {
    constructor(
        address rateFeed_,
        address firstFeed_,
        uint256 firstHeartbeat_,
        address secondFeed_,
        uint256 secondHeartbeat_,
        uint256 priceDivisor_,
        bool invertPrice_
    )
        Aggregator_SingleRate_DoublePrice(
            rateFeed_,
            firstFeed_,
            firstHeartbeat_,
            secondFeed_,
            secondHeartbeat_,
            priceDivisor_,
            invertPrice_
        )
    {}

    function _baseName() internal pure override returns (string memory) {
        return "USDE";
    }

    function _quoteName() internal pure override returns (string memory) {
        return "ETH";
    }
}
