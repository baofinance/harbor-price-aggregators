// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {HarborAggregator_v3} from "@harbor-price/aggregators/HarborAggregator_v3.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {ChainlinkRateLib} from "@harbor-price/rates/ChainlinkRateLib.sol";
import {ChainlinkFeedLib} from "@harbor-price/feeds/chainlink/ChainlinkFeedLib.sol";

/// @notice stETH/USD oracle (rate: wstETH/stETH, price: (stETH/ETH) × (ETH/USD)).
/// @dev This is the formula contract; wiring (feeds/addresses) is provided via constructor.
/// @custom:oz-upgrades-unsafe-allow state-variable-immutable constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_stETH_USD is HarborAggregator_v3 {
    error InvalidAddress(address value);

    AggregatorV3Interface public immutable RATE_FEED;
    AggregatorV3Interface public immutable STETH_ETH_FEED;
    uint8 public immutable STETH_ETH_DECIMALS;
    uint256 public immutable STETH_ETH_HEARTBEAT;
    AggregatorV3Interface public immutable ETH_USD_FEED;
    uint8 public immutable ETH_USD_DECIMALS;
    uint256 public immutable ETH_USD_HEARTBEAT;

    constructor(
        address rateFeed_,
        address stethEthFeed_,
        uint256 stethEthHeartbeat_,
        address ethUsdFeed_,
        uint256 ethUsdHeartbeat_
    ) {
        if (rateFeed_ == address(0)) revert InvalidAddress(rateFeed_);
        if (stethEthFeed_ == address(0)) revert InvalidAddress(stethEthFeed_);
        if (ethUsdFeed_ == address(0)) revert InvalidAddress(ethUsdFeed_);

        RATE_FEED = AggregatorV3Interface(rateFeed_);

        STETH_ETH_FEED = AggregatorV3Interface(stethEthFeed_);
        STETH_ETH_DECIMALS = STETH_ETH_FEED.decimals();
        STETH_ETH_HEARTBEAT = stethEthHeartbeat_;

        ETH_USD_FEED = AggregatorV3Interface(ethUsdFeed_);
        ETH_USD_DECIMALS = ETH_USD_FEED.decimals();
        ETH_USD_HEARTBEAT = ethUsdHeartbeat_;
    }

    function rateProvider() external view returns (address) {
        return address(RATE_FEED);
    }

    function _baseName() internal pure override returns (string memory) {
        return "stETH";
    }

    function _quoteName() internal pure override returns (string memory) {
        return "USD";
    }

    /// @inheritdoc IWrappedPriceOracle
    function latestAnswer() external view override(IWrappedPriceOracle) returns (uint256, uint256, uint256, uint256) {
        uint256 rate = ChainlinkRateLib.getRate(RATE_FEED);
        uint256 stethEth = ChainlinkFeedLib.latestAnswerNormalized(
            STETH_ETH_FEED,
            STETH_ETH_DECIMALS,
            STETH_ETH_HEARTBEAT
        );
        uint256 ethUsd = ChainlinkFeedLib.latestAnswerNormalized(ETH_USD_FEED, ETH_USD_DECIMALS, ETH_USD_HEARTBEAT);
        uint256 price = Math.mulDiv(stethEth, ethUsd, 1e18);
        return (price, price, rate, rate);
    }
}
