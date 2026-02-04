// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ISUSDe} from "@harbor-price/interfaces/ISUSDe.sol";

library SUSDeRateLib {
    error InvalidRate(uint256 rate);

    uint256 internal constant DEFAULT_MIN_RATE = 9e17; // 0.9

    /// @notice Get the raw conversion rate for a given amount of sUSDe shares
    /// @param susde The sUSDe vault contract
    /// @param shares The amount of shares to convert
    /// @return The equivalent amount of assets (USDe)
    function getRaw(ISUSDe susde, uint256 shares) internal view returns (uint256) {
        return susde.convertToAssets(shares);
    }

    /// @notice Get the rate for 1e18 shares with default minimum rate validation
    /// @param susde The sUSDe vault contract
    /// @return The rate (assets per share, scaled by 1e18)
    function getRate(ISUSDe susde) internal view returns (uint256) {
        return getRate(susde, DEFAULT_MIN_RATE);
    }

    /// @notice Get the rate for 1e18 shares with custom minimum rate validation
    /// @param susde The sUSDe vault contract
    /// @param minRate The minimum acceptable rate
    /// @return The rate (assets per share, scaled by 1e18)
    function getRate(ISUSDe susde, uint256 minRate) internal view returns (uint256) {
        uint256 rate = getRaw(susde, 1e18);
        if (rate < minRate) revert InvalidRate(rate);
        return rate;
    }
}
