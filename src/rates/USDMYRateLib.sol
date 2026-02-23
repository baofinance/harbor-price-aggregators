// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IUSDMY} from "@harbor-price/interfaces/IUSDMY.sol";

library USDMYRateLib {
    error InvalidRate(uint256 rate);

    uint256 internal constant DEFAULT_MIN_RATE = 9e17; // 0.9

    /// @notice Get the raw conversion rate for a given amount of USDMY shares
    /// @param usdmy The USDMY vault contract
    /// @param shares The amount of shares to convert
    /// @return The equivalent amount of assets (USDM)
    function getRaw(IUSDMY usdmy, uint256 shares) internal view returns (uint256) {
        return usdmy.convertToAssets(shares);
    }

    /// @notice Get the rate for 1e18 shares with default minimum rate validation
    /// @param usdmy The USDMY vault contract
    /// @return The rate (assets per share, scaled by 1e18)
    function getRate(IUSDMY usdmy) internal view returns (uint256) {
        return getRate(usdmy, DEFAULT_MIN_RATE);
    }

    /// @notice Get the rate for 1e18 shares with custom minimum rate validation
    /// @param usdmy The USDMY vault contract
    /// @param minRate The minimum acceptable rate
    /// @return The rate (assets per share, scaled by 1e18)
    function getRate(IUSDMY usdmy, uint256 minRate) internal view returns (uint256) {
        uint256 rate = getRaw(usdmy, 1e18);
        if (rate < minRate) revert InvalidRate(rate);
        return rate;
    }
}
