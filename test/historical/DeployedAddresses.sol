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
