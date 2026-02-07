// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {LeveragedTokenUSDAggregatorTestBase} from "./LeveragedTokenUSDAggregatorTestBase.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";
import {Aggregator_hsstETH_BTC_USD} from "@harbor-price/aggregators/mainnet/Aggregator_hsstETH_BTC_USD.sol";

contract Aggregator_hsstETH_BTC_USD_Test is LeveragedTokenUSDAggregatorTestBase {
    function _contractName() internal pure override returns (string memory) {
        return type(Aggregator_hsstETH_BTC_USD).name;
    }

    function _expectedBaseName() internal pure override returns (string memory) {
        return "hsstETH-BTC";
    }

    function _createAggregator(
        address minter,
        uint8,
        address,
        address underlyingUsdFeed,
        uint256 underlyingUsdHeartbeat,
        string memory
    ) internal override returns (IHarborPriceAggregatorV3) {
        if (underlyingUsdFeed == address(0)) underlyingUsdFeed = address(mockUnderlyingUsdFeed);
        if (underlyingUsdHeartbeat == 0) underlyingUsdHeartbeat = DEFAULT_HEARTBEAT;
        return
            IHarborPriceAggregatorV3(
                address(
                    new Aggregator_hsstETH_BTC_USD(
                        minter,
                        underlyingUsdFeed,
                        underlyingUsdHeartbeat,
                        1,
                        false
                    )
                )
            );
    }

    function _createWithZeroMinter() internal override {
        new Aggregator_hsstETH_BTC_USD(
            address(0),
            address(mockUnderlyingUsdFeed),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    function _createWithZeroUnderlying() internal override {
        new Aggregator_hsstETH_BTC_USD(
            address(mockMinter),
            address(0),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    function _createWithZeroUnderlyingUsdFeed() internal override {
        new Aggregator_hsstETH_BTC_USD(
            address(mockMinter),
            address(0),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    function test_latestAnswer_priceIsRateTimesFeedPrice() public view {
        (uint256 p1, uint256 p2, uint256 r1, uint256 r2) = aggregator.latestAnswer();
        assertEq(p1, p2, "price1 == price2");
        assertEq(r1, r2, "rate1 == rate2");
        assertEq(p1, 3600e18, "price should be rate * feedPrice (1.2e18 * 3000e18)");
        assertEq(r1, VALID_LEVERAGED_TOKEN_PRICE, "rate from minter");
    }
}
