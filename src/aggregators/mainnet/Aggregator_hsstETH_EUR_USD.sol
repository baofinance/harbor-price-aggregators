// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "@chainlink/contracts/shared/interfaces/AggregatorV3Interface.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {HarborAggregator_v3} from "@harbor-price/aggregators/HarborAggregator_v3.sol";
import {IWrappedPriceOracle} from "@bao/interfaces/IWrappedPriceOracle.sol";
import {IMinter} from "@harbor-price/interfaces/IMinter.sol";
import {SingleFeedPriceLib} from "@harbor-price/prices/SingleFeedPriceLib.sol";

/// @notice hsstETH-EUR/USD oracle (rate: minter leveragedTokenPrice, price: rate × single-feed price).
/// @dev Same single-feed pattern; rate from minter. Feed must be EUR/USD so price in USD = rate × EUR/USD.
/// @custom:oz-upgrades-unsafe-allow state-variable-immutable constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_hsstETH_EUR_USD is HarborAggregator_v3 {
    IMinter public immutable MINTER;

    AggregatorV3Interface public immutable PRICE_FEED;
    uint8 public immutable PRICE_FEED_DECIMALS;
    uint256 public immutable PRICE_FEED_HEARTBEAT;
    uint256 public immutable PRICE_DIVISOR;
    bool public immutable INVERT_PRICE;

    constructor(
        address minter_,
        address priceFeed_,
        uint256 priceHeartbeat_,
        uint256 priceDivisor_,
        bool invertPrice_
    ) {
        if (minter_ == address(0)) revert InvalidAddress(minter_);
        if (priceFeed_ == address(0)) revert InvalidAddress(priceFeed_);
        if (priceDivisor_ == 0) revert InvalidDivisor(priceDivisor_);

        MINTER = IMinter(minter_);

        PRICE_FEED = AggregatorV3Interface(priceFeed_);
        PRICE_FEED_DECIMALS = PRICE_FEED.decimals();
        PRICE_FEED_HEARTBEAT = priceHeartbeat_;
        PRICE_DIVISOR = priceDivisor_;
        INVERT_PRICE = invertPrice_;
    }

    function rateProvider() external view returns (address) {
        return address(MINTER);
    }

    function _baseName() internal pure override returns (string memory) {
        return "hsstETH-EUR";
    }

    function _quoteName() internal pure override returns (string memory) {
        return "USD";
    }

    /// @inheritdoc IWrappedPriceOracle
    /// @dev Zero is a legitimate answer, and means the leveraged token is worth nothing. The rate is the
    ///      Minter's `leveragedTokenPrice()`, which is exactly zero once a market is fully capped, and the rate
    ///      is also a factor of the price, so the whole answer becomes (0, 0, 0, 0). A consumer must report
    ///      that as a value rather than treat it as a failure to price - see `IMinter.leveragedTokenPrice`.
    ///
    ///      Unavailability arrives as a revert instead, from either source: the Minter reads its own price
    ///      oracle through a validating reader that reverts rather than return a zero price, and
    ///      `SingleFeedPriceLib` rejects this contract's own feed when it is stale, negative or zero. So a zero
    ///      here can only have come from a wiped-out junior claim, never from a source that could not answer.
    function latestAnswer() external view override(IWrappedPriceOracle) returns (uint256, uint256, uint256, uint256) {
        uint256 rate = MINTER.leveragedTokenPrice();

        uint256 feedPrice = SingleFeedPriceLib.getPrice(
            PRICE_FEED,
            PRICE_FEED_DECIMALS,
            PRICE_FEED_HEARTBEAT,
            PRICE_DIVISOR,
            INVERT_PRICE
        );

        uint256 price = Math.mulDiv(rate, feedPrice, 1e18);

        return (price, price, rate, rate);
    }
}
