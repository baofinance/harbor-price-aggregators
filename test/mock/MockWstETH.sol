// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28 <0.9.0;

import {IWstETH} from "@bao/interfaces/IWstETH.sol";

/// @notice Simple mock wstETH stub for testing. Only implements rate-related functions; rest are stubs.
/// @dev This is a minimal stub. For a full ERC20 implementation, see MockWstETH.sol
contract MockWstETH is IWstETH {
    uint256 private _stEthPerToken;

    function setStEthPerToken(uint256 rate) external {
        _stEthPerToken = rate;
    }

    function stEthPerToken() external view override returns (uint256) {
        return _stEthPerToken;
    }

    function getStETHByWstETH(uint256 wstETHAmount) external view override returns (uint256) {
        return (wstETHAmount * _stEthPerToken) / 1e18;
    }

    function getWstETHByStETH(uint256 stETHAmount) external view override returns (uint256) {
        return (stETHAmount * 1e18) / _stEthPerToken;
    }

    function tokensPerStEth() external view override returns (uint256) {
        return _stEthPerToken;
    }

    function allowance(address, address) external pure override returns (uint256) {
        return 0;
    }

    function approve(address, uint256) external pure override returns (bool) {
        return true;
    }

    function balanceOf(address) external pure override returns (uint256) {
        return 0;
    }

    function totalSupply() external pure override returns (uint256) {
        return 0;
    }

    function transfer(address, uint256) external pure override returns (bool) {
        return true;
    }

    function transferFrom(address, address, uint256) external pure override returns (bool) {
        return true;
    }
}
