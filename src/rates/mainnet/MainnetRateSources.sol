// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// @title Rate Source Addresses - Ethereum Mainnet
/// @notice Token and rate source addresses for computing rates
library MainnetRateSources {
    // Tokens
    address internal constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address internal constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;

    // Rate sources
    address internal constant FXSAVE = 0x7743e50F534a7f9F1791DdE7dCD89F7783Eefc39;
}
