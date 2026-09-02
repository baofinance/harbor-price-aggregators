// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IPriceOracleErrors} from "@bao/interfaces/IPriceOracleErrors.sol";
import {IWstETH} from "@bao/interfaces/IWstETH.sol";

library WstETHRateLib {
    uint256 internal constant DEFAULT_MIN_RATE = 9e17; // 0.9
    uint256 internal constant DEFAULT_MAX_RATE = 3e18;

    function getRaw(IWstETH wsteth, uint256 wstethAmount) internal view returns (uint256) {
        return wsteth.getStETHByWstETH(wstethAmount);
    }

    function getRate(IWstETH wsteth) internal view returns (uint256) {
        return getRate(wsteth, DEFAULT_MIN_RATE, DEFAULT_MAX_RATE);
    }

    function getRate(IWstETH wsteth, uint256 minRate, uint256 maxRate) internal view returns (uint256) {
        uint256 rate = getRaw(wsteth, 1e18);
        if (rate < minRate || rate > maxRate) revert IPriceOracleErrors.InvalidRate(rate);
        return rate;
    }
}
