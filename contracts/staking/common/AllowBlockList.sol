// Copyright (c) Immutable Pty Ltd 2023
// SPDX-License-Identifier: Apache2
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 *  @title AllowBlockList
 *  @notice Functions to allow or block a certain addresses.
 *  @dev Not designed to be upgradeable.
 */
abstract contract AllowBlockList is AccessControl {
    bytes32 public constant ACCOUNT_ADMIN_ROLE = bytes32(uint256(0x02));

    enum AllowBlockMode {
        Disabled,
        AllowListEnabled,
        DisallowListEnabled
    }
    AllowBlockMode public mode;
    mapping(address => bool) public allowList;
    mapping(address => bool) public disallowList;

    error CantEnableBothAllowListAndDisallowList();
    error AlreadyAllowed(address _account);
    error AlreadyDisallowed(address _account);
    error NotAllowed(address _account);
    error NotDisallowed(address _account);
    error StakerNotAllowed(address _account);

    modifier onlyAllowedStaker() {
        if (!isAllowed(msg.sender)) {
            revert StakerNotAllowed(msg.sender);
        }
        _;
    }

    constructor() {
        mode = AllowBlockMode.Disabled;
    }

    /**
     * @notice Set the mode of operation
     * @param _enableAllowList True if the allow list should be enabled.
     * @param _enableDisallowList Trust if the disallow list should be enabled.
     */
    function setAllowDisallowMode(
        bool _enableAllowList,
        bool _enableDisallowList
    ) external onlyRole(ACCOUNT_ADMIN_ROLE) {
        if (!_enableAllowList && !_enableDisallowList) {
            mode = AllowBlockMode.Disabled;
        } else if (_enableAllowList && !_enableDisallowList) {
            mode = AllowBlockMode.AllowListEnabled;
        } else if (!_enableAllowList && _enableDisallowList) {
            mode = AllowBlockMode.DisallowListEnabled;
        } else {
            revert CantEnableBothAllowListAndDisallowList();
        }
    }

    /**
     * @notice Add one or more accounts to the allow list.
     * @param _accounts Array of accounts to add to the allow list.
     */
    function addToAllowList(address[] calldata _accounts) external onlyRole(ACCOUNT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            if (allowList[account]) {
                revert AlreadyAllowed(account);
            }
            allowList[account] = true;
        }
    }

    /**
     * @notice Remove one or more accounts from the allow list.
     * @param _accounts Array of accounts to remove from the allow list.
     */
    function removeFromAllowList(address[] calldata _accounts) external onlyRole(ACCOUNT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            if (!allowList[account]) {
                revert NotAllowed(account);
            }
            allowList[account] = false;
        }
    }

    /**
     * @notice Add one or more accounts to the disallow list.
     * @param _accounts Array of accounts to add to the disallow list.
     */
    function addToDisallowList(address[] calldata _accounts) external onlyRole(ACCOUNT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            if (disallowList[account]) {
                revert AlreadyDisallowed(account);
            }
            disallowList[account] = true;
        }
    }

    /**
     * @notice Remove one or more accounts from the disallow lis
     * @param _accounts Array of accounts to remove from the disallow list.
     */
    function removeFromDisallowList(address[] calldata _accounts) external onlyRole(ACCOUNT_ADMIN_ROLE) {
        for (uint256 i = 0; i < _accounts.length; i++) {
            address account = _accounts[i];
            if (!disallowList[account]) {
                revert NotAllowed(account);
            }
            disallowList[account] = false;
        }
    }

    /**
     * @notice Determine if an account is allowed.
     */
    function isAllowed(address _account) public view returns (bool) {
        AllowBlockMode currentMode = mode;
        if (currentMode == AllowBlockMode.AllowListEnabled) {
            return allowList[_account];
        }
        if (currentMode == AllowBlockMode.DisallowListEnabled) {
            return !disallowList[_account];
        }
        return true;
    }
}
