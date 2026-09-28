// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {WiredAggregatorHarness} from "@harbor-price-test/conformance/WiredAggregatorHarness.sol";

/// @title An aggregator whose price is one feed multiplied by another
/// @notice The feeds chain rather than share a denominator: the first quotes the base against an
///         intermediate asset and the second quotes that intermediate against the quote, so
///         multiplying them carries the base through to the quote. wBTC/BTC times BTC/USD is
///         wBTC/USD; stETH/ETH times ETH/USD is stETH/USD.
/// @dev This is the shape most easily confused with the divided one — the same two feeds, composed
///      the other way — and the two answers differ by many orders of magnitude at the values the
///      harness drives, so neither can pass for the other.
abstract contract WiredMultipliedFeedsHarness is WiredAggregatorHarness {
    /// @inheritdoc WiredAggregatorHarness
    function _expectedPrice() internal view override returns (uint256) {
        // Both answers carry 18 decimals, so their product carries 36 and is brought back to 18.
        return _scaledByRate((_priceAnswer(0) * _priceAnswer(1)) / 1e18);
    }
}
