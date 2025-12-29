// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @notice Canonical Base chain addresses and default constraints for Harbor price aggregators.
library BaseOracleAddresses {
    // Tokens
    address internal constant STETH = address(0); // Not deployed on Base
    address internal constant WSTETH = 0xc1CBa3fCea344f92D9239c08C0568f6F2F0ee452; // wstETH on Base

    // Rate sources
    address internal constant FXSAVE = address(0); // Not used

    // Chainlink feeds
    address internal constant ETH_USD_FEED = 0x71041dddad3595F9CEd3DcCFBe3D1F4b0a16Bb70;
    address internal constant BTC_USD_FEED = address(0); // Not used on Base
    address internal constant STETH_ETH_FEED = 0xf586d0728a47229e747d824a939000Cf21dEF5A0;
    address internal constant STETH_USD_FEED = ETH_USD_FEED; // Default to ETH/USD if no direct stETH/USD feed
    address internal constant WSTETH_STETH_FEED = 0xB88BAc61a4Ca37C43a3725912B1f472c9A5bc061;

    // Additional Chainlink feeds (if needed)
    address internal constant USDC_USD_FEED = address(0);
    address internal constant EUR_USD_FEED = address(0);
    address internal constant XAU_USD_FEED = address(0);
    address internal constant MCAP_USD_FEED = address(0);

    // Meme coin feeds on Base (used for normalization contracts)
    address internal constant DOGE_USD_FEED = 0x8422f3d3CAFf15Ca682939310d6A5e619AE08e57;
    address internal constant SHIB_USD_FEED = 0xC8D5D660bb585b68fa0263EeD7B4224a5FC99669;
    address internal constant PEPE_USD_FEED = 0xB48ac6409C0c3718b956089b0fFE295A10ACDdad;
    address internal constant TRUMP_USD_FEED = 0x7bAfa1Af54f17cC0775a1Cf813B9fF5dED2C51E5;
    address internal constant WIF_USD_FEED = 0x674940e1dBf7FD841b33156DA9A88afbD95AaFBa;

    // Meme coin normalization factors (18 decimals)
    // These normalize each coin's price to WIF's total supply (~998.84M)
    // Formula: normalized_price = original_price * normalization_factor
    uint256 internal constant DOGE_NORM_FACTOR = 168_200_000_000_000_000_000; // 168.2e18 (WIF_supply / DOGE_circ_supply ≈ 998.84M / 168B)
    uint256 internal constant SHIB_NORM_FACTOR = 589_500_000_000_000_000_000_000; // 589500e18 (WIF_supply / SHIB_max_supply)
    uint256 internal constant PEPE_NORM_FACTOR = 421_000_000_000_000_000_000_000; // 421000e18 (WIF_supply / PEPE_max_supply)
    uint256 internal constant TRUMP_NORM_FACTOR = 998_840_000_000_000_000; // ~0.99884e18 (WIF_max / TRUMP_max ≈ 998.84M / 1B)
    uint256 internal constant WIF_NORM_FACTOR = 1_000_000_000_000_000_000; // 1e18 (WIF_max / WIF_max = 1.0, no change)

    // Chainlink feeds that are unused on Base for current rate sources but may be required by constructors.
    address internal constant SUSDE_USDE_FEED = address(0);

    // Constraints
    uint64 internal constant MAX_AGE = 604_800; // 7 days
    uint256 internal constant MAX_DEV = 50_000_000_000_000_000; // 5e16 == 5%
}

