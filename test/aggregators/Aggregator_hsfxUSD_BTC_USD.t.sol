// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/console.sol";
import {LeveragedTokenUSDAggregatorTestBase} from "./LeveragedTokenUSDAggregatorTestBase.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";
import {Aggregator_hsfxUSD_BTC_USD} from "@harbor-price/aggregators/mainnet/Aggregator_hsfxUSD_BTC_USD.sol";

contract Aggregator_hsfxUSD_BTC_USD_Test is LeveragedTokenUSDAggregatorTestBase {
    function _contractName() internal pure override returns (string memory) {
        return type(Aggregator_hsfxUSD_BTC_USD).name;
    }

    function _expectedBaseName() internal pure override returns (string memory) {
        return "hsfxUSD-BTC";
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
                    new Aggregator_hsfxUSD_BTC_USD(
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
        new Aggregator_hsfxUSD_BTC_USD(
            address(0),
            address(mockUnderlyingUsdFeed),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    function _createWithZeroUnderlying() internal override {
        new Aggregator_hsfxUSD_BTC_USD(
            address(mockMinter),
            address(0),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    function _createWithZeroUnderlyingUsdFeed() internal override {
        new Aggregator_hsfxUSD_BTC_USD(
            address(mockMinter),
            address(0),
            DEFAULT_HEARTBEAT,
            1,
            false
        );
    }

    /// @notice Price = rate × feed price (single-feed pattern)
    function test_latestAnswer_priceIsRateTimesFeedPrice() public view {
        (uint256 p1, uint256 p2, uint256 r1, uint256 r2) = aggregator.latestAnswer();
        assertEq(p1, p2, "price1 == price2");
        assertEq(r1, r2, "rate1 == rate2");
        // mockUnderlyingUsdFeed = 3000e8 (8 decimals) -> 3000e18 from SingleFeedPriceLib
        // rate = VALID_LEVERAGED_TOKEN_PRICE = 1.2e18
        // price = 1.2e18 * 3000e18 / 1e18 = 3600e18
        assertEq(p1, 3600e18, "price should be rate * feedPrice");
        assertEq(r1, VALID_LEVERAGED_TOKEN_PRICE, "rate from minter");
    }

    /// @notice Run with real-world values: leverage token price 1847348514454581040, BTC feed 7014427470822 (8 decimals).
    /// @dev INVERT_PRICE = false for BTC/USD (feed returns USD per BTC). Output should be ~129k USD (18 decimals).
    function test_latestAnswer_realWorldValues_outputAround129k() public {
        uint256 leverageTokenPrice = 1847348514454581040;
        uint256 btcUsdRaw = 7014427470822; // 70144.27470822 USD with 8 decimals

        mockMinter.setLeveragedTokenPrice(leverageTokenPrice);
        mockUnderlyingUsdFeed.setAnswer(int256(uint256(btcUsdRaw)), block.timestamp);

        (uint256 price, , uint256 rate, ) = aggregator.latestAnswer();

        console.log("rate (leveragedTokenPrice, 18 decimals):", rate);
        console.log("BTC/USD feed raw (8 decimals):", btcUsdRaw);
        console.log("output price (18 decimals):", price);
        console.log("output price in USD (price/1e18):", price / 1e18);

        // Expected: rate * feedPrice / 1e18 = 1847348514454581040 * 70144274708220000000000 / 1e18 ~= 129548e18
        assertApproxEqRel(price, 129548e18, 0.001e18, "price should be ~129548 USD (18 decimals)");
    }
}
