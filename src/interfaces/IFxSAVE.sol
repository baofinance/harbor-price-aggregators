// SPDX-License-Identifier: MIT AND GPL-3.0
pragma solidity >=0.8.28 <0.9.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

interface IFxSAVE is IERC20, IERC4626 {
    /**
     * @notice Convert an amount of shares to the equivalent amount of assets
     * @param shares The amount of shares to convert
     * @return The equivalent amount of assets
     */
    function convertToAssets(uint256 shares) external view returns (uint256);

    /**
     * @notice Role identifier for claiming on behalf of others
     * @return The bytes32 role identifier
     */
    function CLAIM_FOR_ROLE() external view returns (bytes32);

    /**
     * @notice Role identifier for the default admin role
     * @return The bytes32 role identifier
     */
    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Get the EIP-712 domain separator
     * @return The domain separator
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /**
     * @notice Get the address of the base token
     * @return The address of the base token
     */
    function base() external view returns (address);

    /**
     * @notice Get the address of the gauge contract
     * @return The address of the gauge contract
     */
    function gauge() external view returns (address);

    /**
     * @notice Get the current expense ratio
     * @return The expense ratio
     */
    function getExpenseRatio() external view returns (uint256);

    /**
     * @notice Get the current harvester ratio
     * @return The harvester ratio
     */
    function getHarvesterRatio() external view returns (uint256);

    /**
     * @notice Get the admin role for a given role
     * @param role The role to query
     * @return The admin role identifier
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @notice Get the current threshold
     * @return The threshold value
     */
    function getThreshold() external view returns (uint256);

    /**
     * @notice Check if an account has a specific role
     * @param role The role to check
     * @param account The account to check
     * @return True if the account has the role, false otherwise
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @notice Get the address of the harvester
     * @return The harvester address
     */
    function harvester() external view returns (address);

    /**
     * @notice Get the locked proxy address for a given account
     * @param account The account to query
     * @return The locked proxy address
     */
    function lockedProxy(address account) external view returns (address);

    /**
     * @notice Get the maximum deposit amount for an account
     * @param account The account to query
     * @return The maximum deposit amount
     */
    function maxDeposit(address account) external view returns (uint256);

    /**
     * @notice Get the maximum mint amount for an account
     * @param account The account to query
     * @return The maximum mint amount
     */
    function maxMint(address account) external view returns (uint256);

    /**
     * @notice Get the maximum redeem amount for an owner
     * @param owner The owner to query
     * @return The maximum redeem amount
     */
    function maxRedeem(address owner) external view returns (uint256);

    /**
     * @notice Get the maximum withdraw amount for an owner
     * @param owner The owner to query
     * @return The maximum withdraw amount
     */
    function maxWithdraw(address owner) external view returns (uint256);

    /**
     * @notice Get the nonce for an owner (for EIP-2612 permits)
     * @param owner The owner to query
     * @return The current nonce
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @notice Get the net asset value (NAV) of the vault
     * @return The net asset value
     */
    function nav() external view returns (uint256);

    /**
     * @notice Get the treasury address
     * @return The treasury address
     */
    function treasury() external view returns (address);

    /**
     * @notice Get the vault address
     * @return The vault address
     */
    function vault() external view returns (address);

    /**
     * @notice Get the EIP-712 domain information
     * @return fields The EIP-712 domain fields
     * @return name The name of the contract
     * @return version The version of the contract
     * @return chainId The chain ID
     * @return verifyingContract The verifying contract address
     * @return salt The salt for the domain
     * @return extensions Any extensions for the domain
     */
    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        );

    /**
     * @notice Check if the contract supports a given interface
     * @param interfaceId The interface identifier
     * @return True if the interface is supported, false otherwise
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // Events
    event Claim(address owner, address receiver);
    event EIP712DomainChanged();
    event Initialized(uint64 version);
    event RequestRedeem(address owner, uint256 shares, uint256 assets);
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    event UpdateExpenseRatio(uint256 oldRatio, uint256 newRatio);
    event UpdateHarvester(address indexed oldHarvester, address indexed newHarvester);
    event UpdateHarvesterRatio(uint256 oldRatio, uint256 newRatio);
    event UpdateThreshold(uint256 oldThreshold, uint256 newThreshold);
    event UpdateTreasury(address indexed oldTreasury, address indexed newTreasury);
}
