// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Base Oracle Constants
/// @notice Constants used by Base v3 oracles
library BaseConstants {
    // Meme coin normalization factors (18 decimals)
    // These normalize each coin's price to WIF's total supply (~998.84M)
    // Formula: normalized_price = original_price * normalization_factor
    uint256 internal constant DOGE_NORM_FACTOR = 168_200_000_000_000_000_000; // 168.2e18 (WIF_supply / DOGE_circ_supply ≈ 998.84M / 168B)
    uint256 internal constant SHIB_NORM_FACTOR = 589_500_000_000_000_000_000_000; // 589500e18 (WIF_supply / SHIB_max_supply)
    uint256 internal constant PEPE_NORM_FACTOR = 421_000_000_000_000_000_000_000; // 421000e18 (WIF_supply / PEPE_max_supply)
    uint256 internal constant TRUMP_NORM_FACTOR = 998_840_000_000_000_000; // ~0.99884e18 (WIF_max / TRUMP_max ≈ 998.84M / 1B)
    uint256 internal constant WIF_NORM_FACTOR = 1_000_000_000_000_000_000; // 1e18 (WIF_max / WIF_max = 1.0, no change)
}
