// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IFxSAVE} from "@harbor-price/interfaces/IFxSAVE.sol";

library FxSaveRateLib {
    error InvalidRate(uint256 rate);

    uint256 internal constant DEFAULT_MIN_RATE = 9e17; // 0.9

    function getRaw(IFxSAVE fxsave, uint256 shares) internal view returns (uint256) {
        return fxsave.convertToAssets(shares);
    }

    function getRate(IFxSAVE fxsave) internal view returns (uint256) {
        return getRate(fxsave, DEFAULT_MIN_RATE);
    }

    function getRate(IFxSAVE fxsave, uint256 minRate) internal view returns (uint256) {
        uint256 rate = getRaw(fxsave, 1e18);
        if (rate < minRate) revert InvalidRate(rate);
        return rate;
    }
}
