// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28 <0.9.0;

import {IMinter} from "@harbor-price/interfaces/IMinter.sol";

/// @notice Mock Minter for testing. Implements leveragedTokenPrice().
contract MockMinter is IMinter {
    uint256 private _leveragedTokenPrice;

    function setLeveragedTokenPrice(uint256 price) external {
        _leveragedTokenPrice = price;
    }

    function leveragedTokenPrice() external view override returns (uint256) {
        return _leveragedTokenPrice;
    }
}
