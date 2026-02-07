// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Rate Source Addresses - Ethereum Mainnet
/// @notice Token and rate source addresses for computing rates
library MainnetRateSources {
    address internal constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address internal constant FXSAVE = 0x7743e50F534a7f9F1791DdE7dCD89F7783Eefc39;
    address internal constant SUSDE = 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497;
    
    // Leveraged Token Minters
    address internal constant MINTER_HSFXUSD_EUR = 0xDEFB2C04062350678965CBF38A216Cc50723B246;
    address internal constant MINTER_HSSTETH_EUR = 0x68911ea33E11bc77e07f6dA4db6cd23d723641cE;
    address internal constant MINTER_HSSTETH_BTC = 0xF42516EB885E737780EB864dd07cEc8628000919;
    address internal constant MINTER_HSFXUSD_BTC = 0x33e32ff4d0677862fa31582CC654a25b9b1e4888;
    address internal constant MINTER_HSFXUSD_ETH = 0xd6E2F8e57b4aFB51C6fA4cbC012e1cE6aEad989F;
}
