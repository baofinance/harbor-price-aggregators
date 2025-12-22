// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IWrappedPriceOracle} from "./IWrappedPriceOracle.sol";

/// @notice v3 oracle interface: IWrappedPriceOracle + identity.
interface IHarborPriceAggregatorV3 is IWrappedPriceOracle {
    /// @notice Base asset address (e.g. fxUSD token).
    function base() external view returns (address);

    /// @notice Address of the rate provider used by this oracle (e.g. fxSAVE / wstETH).
    function rateProvider() external view returns (address);

    /// @notice Quote name (e.g. "ETH", "BTC", "EUR").
    function quoteName() external pure returns (string memory);

    /// @notice Derived oracle name (not stored, not updatable).
    function oracleName() external pure returns (string memory);

    /// @notice Oracle version.
    function version() external pure returns (uint256);
}
