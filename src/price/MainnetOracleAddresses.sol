// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @notice Canonical Ethereum mainnet addresses and default constraints for Harbor price aggregators.
library MainnetOracleAddresses {
    // Tokens
    address internal constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address internal constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    // Rate sources
    address internal constant FXSAVE = 0x7743e50F534a7f9F1791DdE7dCD89F7783Eefc39;

    // Chainlink feeds
    address internal constant ETH_USD_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address internal constant BTC_USD_FEED = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c;

    // Additional Chainlink feeds used by the v2 regression suite and other oracles
    address internal constant USDC_USD_FEED = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
    address internal constant EUR_USD_FEED = 0xb49f677943BC038e9857d61E7d053CaA2C1734C1;
    address internal constant XAU_USD_FEED = 0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6;
    address internal constant MCAP_USD_FEED = 0xEC8761a0A73c34329CA5B1D3Dc7eD07F30e836e2;
    address internal constant STETH_USD_FEED = 0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8;
    address internal constant STETH_ETH_FEED = 0x86392dC19c0b719886221c78AB11eb8Cf5c52812;

    // Chainlink feeds that are unused on mainnet for current rate sources but may be required by constructors.
    address internal constant SUSDE_USDE_FEED = address(0);
    address internal constant WSTETH_STETH_FEED = address(0);

    // Constraints
    uint64 internal constant MAX_AGE = 604_800; // 7 days
    uint256 internal constant MAX_DEV = 50_000_000_000_000_000; // 5e16 == 5%
}
