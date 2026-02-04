// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {HarborAggregator_v3} from "@harbor-price/aggregators/HarborAggregator_v3.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";
import {ISUSDe} from "@harbor-price/interfaces/ISUSDe.sol";
import {SUSDeRateLib} from "@harbor-price/rates/SUSDeRateLib.sol";
import {DoubleFeedPriceLib} from "@harbor-price/prices/DoubleFeedPriceLib.sol";

/// @notice sUSDe/BTC oracle (rate: sUSDe->USDe, price: (USDe/USD)/(BTC/USD)).
/// @dev This is the formula contract; wiring (feeds/addresses) is provided via constructor.
/// @custom:oz-upgrades-unsafe-allow state-variable-immutable constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_sUSDe_BTC is HarborAggregator_v3 {
    using SUSDeRateLib for ISUSDe;

    error InvalidAddress(address value);
    error InvalidDivisor(uint256 divisor);

    ISUSDe public immutable SUSDE;

    AggregatorV3Interface public immutable FIRST_FEED;
    uint8 public immutable FIRST_FEED_DECIMALS;
    uint256 public immutable FIRST_FEED_HEARTBEAT;
    AggregatorV3Interface public immutable SECOND_FEED;
    uint8 public immutable SECOND_FEED_DECIMALS;
    uint256 public immutable SECOND_FEED_HEARTBEAT;

    uint256 public immutable PRICE_DIVISOR;
    bool public immutable INVERT_PRICE;

    constructor(
        address susde_,
        address firstFeed_,
        uint256 firstHeartbeat_,
        address secondFeed_,
        uint256 secondHeartbeat_,
        uint256 priceDivisor_,
        bool invertPrice_
    ) {
        if (susde_ == address(0)) revert InvalidAddress(susde_);
        if (firstFeed_ == address(0)) revert InvalidAddress(firstFeed_);
        if (secondFeed_ == address(0)) revert InvalidAddress(secondFeed_);
        if (priceDivisor_ == 0) revert InvalidDivisor(priceDivisor_);

        SUSDE = ISUSDe(susde_);

        FIRST_FEED = AggregatorV3Interface(firstFeed_);
        FIRST_FEED_DECIMALS = FIRST_FEED.decimals();
        FIRST_FEED_HEARTBEAT = firstHeartbeat_;
        SECOND_FEED = AggregatorV3Interface(secondFeed_);
        SECOND_FEED_DECIMALS = SECOND_FEED.decimals();
        SECOND_FEED_HEARTBEAT = secondHeartbeat_;

        PRICE_DIVISOR = priceDivisor_;
        INVERT_PRICE = invertPrice_;
    }

    function rateProvider() external view returns (address) {
        return address(SUSDE);
    }

    function _baseName() internal pure override returns (string memory) {
        return "sUSDe";
    }

    function _quoteName() internal pure override returns (string memory) {
        return "BTC";
    }

    /// @inheritdoc IWrappedPriceOracle
    function latestAnswer() external view override(IWrappedPriceOracle) returns (uint256, uint256, uint256, uint256) {
        uint256 rate = SUSDE.getRate();

        uint256 price = DoubleFeedPriceLib.getPrice(
            FIRST_FEED,
            FIRST_FEED_DECIMALS,
            FIRST_FEED_HEARTBEAT,
            SECOND_FEED,
            SECOND_FEED_DECIMALS,
            SECOND_FEED_HEARTBEAT,
            PRICE_DIVISOR,
            INVERT_PRICE
        );

        return (price, price, rate, rate);
    }
}
