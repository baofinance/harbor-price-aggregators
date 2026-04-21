// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {HarborAggregator_v3} from "@harbor-price/aggregators/HarborAggregator_v3.sol";
import {IWrappedPriceOracle} from "@harbor-price/interfaces/IWrappedPriceOracle.sol";

/// @notice Trivial ETH/ETH oracle for haETH markets where the peg asset is ETH itself.
/// @dev Returns constant (1e18, 1e18, 1e18, 1e18) — no feeds required.
/// @custom:oz-upgrades-unsafe-allow constructor
// solhint-disable-next-line contract-name-capwords
contract Aggregator_ETH_ETH is HarborAggregator_v3 {
    function rateProvider() external pure returns (address) {
        return address(0);
    }

    function _baseName() internal pure override returns (string memory) {
        return "ETH";
    }

    function _quoteName() internal pure override returns (string memory) {
        return "ETH";
    }

    /// @inheritdoc IWrappedPriceOracle
    function latestAnswer() external pure override(IWrappedPriceOracle) returns (uint256, uint256, uint256, uint256) {
        return (1e18, 1e18, 1e18, 1e18);
    }
}
