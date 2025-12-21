// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Deployed Oracle Addresses
/// @notice Deployed proxy addresses from deployment-state-v2.json (mainnet)
library DeployedAddresses {
    // Implementation contracts
    address internal constant SINGLE_IMPL = 0x3860ae3Df9Fa0Bb56fbdD1c4A6e30bEAa497E0E1;
    address internal constant DOUBLE_IMPL = 0xaC669B64c85F89150f9C0a379dF731E79218C3C5;

    // fxUSD proxies (Single Feed)
    address internal constant FXUSD_ETH = 0x71437C90F1E0785dd691FD02f7bE0B90cd14c097;
    address internal constant FXUSD_BTC = 0x8F76a260c5D21586aFfF18f880FFC808D0524A73;
    address internal constant FXUSD_EUR = 0x6bEb1a1189Ac68a2a26b5210e5ccfB9e8a3E408E;
    address internal constant FXUSD_XAU = 0x7DAe17B00DCd5C37D4992a17C3Cf8f5E15d2BbAf;
    address internal constant FXUSD_MCAP = 0xdF21f32c522B2A871D5a6AD303638051b51C378F;

    // stETH proxies (Double Feed)
    address internal constant STETH_BTC = 0xd8789EB86Dd57f9Fe10D0D8dFa803286b389b1BC;
    address internal constant STETH_EUR = 0x76453e0eaF1a54c0e939b2E66D9825808cBd411b;
    address internal constant STETH_XAU = 0x8919713b1620BCA8bE6e774fFFA735b0051ff6cB;
    address internal constant STETH_MCAP = 0x06CD5701d9FfD9F7AaDFE28C57B481e99D2ba3ad;

    // Deployment info - oracles deployed across blocks 24047052-24047060
    // First (FXUSD_ETH): 24047052, Last (STETH_MCAP): 24047060
    // START_BLOCK is last deployment block so all oracles exist
    uint256 internal constant DEPLOYMENT_BLOCK = 24047060;
}

/// @title Mainnet External Contract Addresses
/// @notice External contract addresses used by the oracles
library MainnetAddresses {
    // Rate source contracts
    address internal constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address internal constant FXSAVE = 0x7743e50F534a7f9F1791DdE7dCD89F7783Eefc39;

    // Chainlink feeds (unused on mainnet for rate sources, but needed for constructor)
    address internal constant SUSDE_USDE_FEED = address(0);
    address internal constant WSTETH_STETH_FEED = address(0);

    // Chainlink price feeds
    address internal constant USDC_USD_FEED = 0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6;
    address internal constant ETH_USD_FEED = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    address internal constant BTC_USD_FEED = 0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c;
    address internal constant EUR_USD_FEED = 0xb49f677943BC038e9857d61E7d053CaA2C1734C1;
    address internal constant XAU_USD_FEED = 0x214eD9Da11D2fbe465a6fc601a91E62EbEc1a0D6;
    address internal constant MCAP_USD_FEED = 0xEC8761a0A73c34329CA5B1D3Dc7eD07F30e836e2;
    address internal constant STETH_USD_FEED = 0xCfE54B5cD566aB89272946F602D76Ea879CAb4a8;
    address internal constant STETH_ETH_FEED = 0x86392dC19c0b719886221c78AB11eb8Cf5c52812;

    // Constraints
    uint64 internal constant MAX_AGE = 604800; // 7 days
    uint256 internal constant MAX_DEV = 50000000000000000; // 5%
}
