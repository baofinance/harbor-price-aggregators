// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// solhint-disable-next-line max-line-length
import {LeveragedTokenUSDAggregatorTestBase} from "@harbor-price-test/aggregators/LeveragedTokenUSDAggregatorTestBase.sol";
import {IHarborPriceAggregatorV3} from "@harbor-price/interfaces/IHarborPriceAggregatorV3.sol";
import {Aggregator_hsstETH_GOLD_USD} from "@harbor-price/aggregators/mainnet/Aggregator_hsstETH_GOLD_USD.sol";

contract Aggregator_hsstETH_GOLD_USD_Test is LeveragedTokenUSDAggregatorTestBase {
    function _contractName() internal pure override returns (string memory) {
        return type(Aggregator_hsstETH_GOLD_USD).name;
    }

    function _expectedBaseName() internal pure override returns (string memory) {
        return "hsstETH-GOLD";
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
                address(new Aggregator_hsstETH_GOLD_USD(minter, underlyingUsdFeed, underlyingUsdHeartbeat, 1, false))
            );
    }

    function _createWithZeroMinter() internal override {
        new Aggregator_hsstETH_GOLD_USD(address(0), address(mockUnderlyingUsdFeed), DEFAULT_HEARTBEAT, 1, false);
    }

    function _createWithZeroUnderlying() internal override {
        new Aggregator_hsstETH_GOLD_USD(address(mockMinter), address(0), DEFAULT_HEARTBEAT, 1, false);
    }

    function _createWithZeroUnderlyingUsdFeed() internal override {
        new Aggregator_hsstETH_GOLD_USD(address(mockMinter), address(0), DEFAULT_HEARTBEAT, 1, false);
    }

    function _createWithZeroDivisor() internal override {
        new Aggregator_hsstETH_GOLD_USD(
            address(mockMinter),
            address(mockUnderlyingUsdFeed),
            DEFAULT_HEARTBEAT,
            0,
            false
        );
    }
}
