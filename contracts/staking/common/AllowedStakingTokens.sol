// Copyright (c) Immutable Pty Ltd 2023
// SPDX-License-Identifier: Apache2
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 *  @title AllowedStakingTokens
 *  @notice Functions to hold a set of tokens that are allowed to be used.
 *  @dev Not designed to be upgradeable.
 */
abstract contract AllowedStakingTokens is AccessControl {
    bytes32 public constant TOKEN_ADMIN_ROLE = bytes32(uint256(0x01));

    enum StakingTokenMode {
        NeverUsed,
        Enabled,
        Disabled
    }

    // Data structures representing the set of tokens that this validator will allow for staking.
    // Note that chains will be selective with which tokens can be staked.
    mapping(address => StakingTokenMode) public allowedStakingTokens;
    address[] private allowedStakingTokensList;

    error TokenAlreadyAllowed(address _token);
    error TokenNotAllowed(address _token);

    /**
     * @notice Add one or more tokens to the list of tokens that can be staked with this validator.
     * @param _tokens Array of tokens to add to the supported list.
     */
    function addAllowedStakingTokens(address[] calldata _tokens) public virtual onlyRole(TOKEN_ADMIN_ROLE) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (allowedStakingTokens[token] == StakingTokenMode.Enabled) {
                revert TokenAlreadyAllowed(token);
            }
            allowedStakingTokensList.push(token);
            allowedStakingTokens[token] = StakingTokenMode.Enabled;
        }
    }

    function removeAllowedStakingTokens(address[] calldata _tokens) public virtual onlyRole(TOKEN_ADMIN_ROLE) {
        for (uint256 i = 0; i < _tokens.length; i++) {
            address token = _tokens[i];
            if (allowedStakingTokens[token] != StakingTokenMode.Enabled) {
                revert TokenNotAllowed(token);
            }
            allowedStakingTokens[token] = StakingTokenMode.Disabled;
            for (uint256 j = 0; j < allowedStakingTokensList.length; j++) {
                if (allowedStakingTokensList[j] == token) {
                    allowedStakingTokensList[j] = address(0);
                }
            }
        }
    }

    /**
     * @notice return the array of supported tokens.
     */
    function getAllowedStakingTokens() external view returns (address[] memory) {
        uint256 numTokens = allowedStakingTokensList.length;
        address[] memory allowedTokens = new address[](numTokens);

        uint256 actualTokens = 0;
        for (uint256 i = 0; i < numTokens; i++) {
            address token = allowedStakingTokensList[i];
            // Skip removed tokens.
            if (token != address(0)) {
                allowedTokens[actualTokens++] = token;
            }
        }
        if (actualTokens != numTokens) {
            // If there were removed tokens, adjust the length of the array.
            address[] memory allowedTokens1 = new address[](actualTokens);
            for (uint256 i = 0; i < actualTokens; i++) {
                allowedTokens1[i] = allowedTokens[i];
            }
            allowedTokens = allowedTokens1;
        }
        return allowedTokens;
    }
}
