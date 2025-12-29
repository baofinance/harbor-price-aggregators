// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @notice Canonical Arbitrum chain addresses and default constraints for Harbor price aggregators.
library ArbitrumOracleAddresses {
    // Tokens
    address internal constant STETH = address(0); // Not directly used (via wstETH)
    address internal constant WSTETH = 0x5979D7b546E38E414F7E9822514be443A4800529;
    address internal constant SUSDE = 0x211Cc4DD073734dA055fbF44a2b4667d5E5fE5d2; // sUSDE token address on Arbitrum

    // Rate sources
    address internal constant FXSAVE = address(0); // Not used for stock oracles

    // Chainlink feeds - Rate feeds
    address internal constant SUSDE_USDE_FEED = 0x605EA726F0259a30db5b7c9ef39Df9fE78665C44;
    address internal constant USDE_USD_FEED = 0x88AC7Bca36567525A866138F03a6F6844868E0Bc;
    address internal constant WSTETH_STETH_FEED = 0xB1552C5e96B312d0Bf8b554186F846C40614a540;
    address internal constant STETH_USD_FEED = 0x07C5b924399cc23c24a95c8743DE4006a32b7f2a;

    // Chainlink feeds - Additional (if needed)
    address internal constant ETH_USD_FEED = address(0);
    address internal constant BTC_USD_FEED = address(0);
    address internal constant USDC_USD_FEED = address(0);
    address internal constant EUR_USD_FEED = address(0);
    address internal constant XAU_USD_FEED = address(0);
    address internal constant MCAP_USD_FEED = address(0);
    address internal constant STETH_ETH_FEED = address(0);

    // Chainlink feeds - Stock price feeds
    address internal constant AAPL_USD_FEED = 0x8d0CC5f38f9E802475f2CFf4F9fc7000C2E1557c;
    address internal constant AMZN_USD_FEED = 0xd6a77691f071E98Df7217BED98f38ae6d2313EBA;
    address internal constant GOOGL_USD_FEED = 0x1D1a83331e9D255EB1Aaf75026B60dFD00A252ba;
    address internal constant META_USD_FEED = 0xcd1bd86fDc33080DCF1b5715B6FCe04eC6F85845;
    address internal constant MSFT_USD_FEED = 0xDde33fb9F21739602806580bdd73BAd831DcA867;
    address internal constant NVDA_USD_FEED = 0x4881A4418b5F2460B21d6F08CD5aA0678a7f262F;
    address internal constant SPY_USD_FEED = 0x46306F3795342117721D8DEd50fbcF6DF2b3cc10;
    address internal constant TSLA_USD_FEED = 0x3609baAa0a9b1f0FE4d6CC01884585d0e191C3E3;

    // MAG7 Index Price (sum of 7 stocks on 1-1-2026)
    // Set to current prices as of deployment - will be updated to 1-1-2026 prices when available
    // Current sum: 2635395000000000000000 (2635.395 in human readable)
    // Breakdown: AAPL: 273.345, MSFT: 487.58, TSLA: 475.075, GOOGL: 313.505, META: 662.945, AMZN: 232.535, NVDA: 190.41
    uint256 internal constant MAG7_I26_INDEX_PRICE = 2635395000000000000000;

    // Constraints
    uint64 internal constant MAX_AGE = 604_800; // 7 days
    uint256 internal constant MAX_DEV = 50_000_000_000_000_000; // 5e16 == 5%
}

