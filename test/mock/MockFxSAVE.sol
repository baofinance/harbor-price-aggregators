// SPDX-License-Identifier: MIT
pragma solidity >=0.8.28 <0.9.0;

import {IFxSAVE} from "@harbor-price/interfaces/IFxSAVE.sol";

/// @notice Mock fxSAVE for testing. Only implements setAssetsPerShare and convertToAssets; rest are stubs.
contract MockFxSAVE is IFxSAVE {
    uint256 private _assetsPerShare;

    function setAssetsPerShare(uint256 rate) external {
        _assetsPerShare = rate;
    }

    function convertToAssets(uint256 shares) external view override returns (uint256) {
        return (shares * _assetsPerShare) / 1e18;
    }

    // IERC4626 functions (stubs)
    function asset() external pure override returns (address) {
        return address(0);
    }
    function convertToShares(uint256) external pure override returns (uint256) {
        return 0;
    }
    function deposit(uint256, address) external pure override returns (uint256) {
        return 0;
    }
    function maxDeposit(address) external pure override returns (uint256) {
        return 0;
    }
    function maxMint(address) external pure override returns (uint256) {
        return 0;
    }
    function maxRedeem(address) external pure override returns (uint256) {
        return 0;
    }
    function maxWithdraw(address) external pure override returns (uint256) {
        return 0;
    }
    function mint(uint256, address) external pure override returns (uint256) {
        return 0;
    }
    function previewDeposit(uint256) external pure override returns (uint256) {
        return 0;
    }
    function previewMint(uint256) external pure override returns (uint256) {
        return 0;
    }
    function previewRedeem(uint256) external pure override returns (uint256) {
        return 0;
    }
    function previewWithdraw(uint256) external pure override returns (uint256) {
        return 0;
    }
    function redeem(uint256, address, address) external pure override returns (uint256) {
        return 0;
    }
    function totalAssets() external pure override returns (uint256) {
        return 0;
    }
    function withdraw(uint256, address, address) external pure override returns (uint256) {
        return 0;
    }

    // IERC20Metadata stubs
    function name() external pure override returns (string memory) {
        return "";
    }
    function symbol() external pure override returns (string memory) {
        return "";
    }
    function decimals() external pure override returns (uint8) {
        return 18;
    }

    // IERC20 stubs
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

    // IFxSAVE-specific stubs
    function CLAIM_FOR_ROLE() external pure override returns (bytes32) {
        return bytes32(0);
    }
    function DEFAULT_ADMIN_ROLE() external pure override returns (bytes32) {
        return bytes32(0);
    }
    function DOMAIN_SEPARATOR() external pure override returns (bytes32) {
        return bytes32(0);
    }
    function base() external pure override returns (address) {
        return address(0);
    }
    function gauge() external pure override returns (address) {
        return address(0);
    }
    function getExpenseRatio() external pure override returns (uint256) {
        return 0;
    }
    function getHarvesterRatio() external pure override returns (uint256) {
        return 0;
    }
    function getRoleAdmin(bytes32) external pure override returns (bytes32) {
        return bytes32(0);
    }
    function getThreshold() external pure override returns (uint256) {
        return 0;
    }
    function harvester() external pure override returns (address) {
        return address(0);
    }
    function hasRole(bytes32, address) external pure override returns (bool) {
        return false;
    }
    function lockedProxy(address) external pure override returns (address) {
        return address(0);
    }
    function nav() external pure override returns (uint256) {
        return 0;
    }
    function nonces(address) external pure override returns (uint256) {
        return 0;
    }
    function supportsInterface(bytes4) external pure override returns (bool) {
        return false;
    }
    function treasury() external pure override returns (address) {
        return address(0);
    }
    function vault() external pure override returns (address) {
        return address(0);
    }
    function eip712Domain()
        external
        pure
        override
        returns (bytes1, string memory, string memory, uint256, address, bytes32, uint256[] memory)
    {
        return (bytes1(0), "", "", 0, address(0), bytes32(0), new uint256[](0));
    }

    function yieldToken() external pure override returns (address) {
        return address(0);
    }
}
