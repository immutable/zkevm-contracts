// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache2
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "../interfaces/root/IStakeController.sol";


/**
 * @title Staker
 * @notice Holds stake for a validator. From the perspective of the staking system, 
 *         this contract is the validator.
 * @dev This contract is upgradeable. 
 */
contract StakerBFT is Ownable2StepUpgradeable {

    error Unauthorized(string message);
    error OnlyOnL2();
    error OnlyOnL3();




//    bytes32 private constant WITHDRAW_SIG = keccak256("WITHDRAW");


    // Address of the staker that is operating the validator node on the child chain.

    // Address of stake manager. 
    IStakeController public stakeController;

    bool public isOnL2;


    modifier onlyOnL2() {
        if (!isOnL2) {
            revert OnlyOnL2();
        }
        _;
    }

    modifier onlyOnL3() {
        if (isOnL2) {
            revert OnlyOnL3();
        }
        _;
    }

    function initialize(address _stakeController, bool _onL2) external {
        __Ownable_init_unchained();
        stakeController = IStakeController(_stakeController);
        isOnL2 = _onL2;
    }

    /**
     * @notice Request that this validator stake on the L2 or on a chain. This function is used to allow
     *  the validator to be used to validator on multiple chains.
     *
     * @param _chainId The id of the chain to validate on.
     * @param _validator The address of the validator on the chain that will be used as part of consensus. 
     *   For improved operational security, this value should be different for each chain and should not be 
     *   the same address as the owner of this contract.
     * @param _commitment This is the initial value of the RANDAO hash onion. This value should be different 
     *   for each chain the validator is validating on.
     */
    function validateOnChain(uint256 _chainId, address _validator, bytes32 _commitment) external onlyOwner() onlyOnL2() {
        stakeController.validateOnChain(_chainId, _validator, _commitment);
    }

    function withdrawNative() external onlyOwner() {
        AddressUpgradeable.sendValue(payable(owner()), address(this).balance);
    }


    /**
     * @notice Allow native tokens to be sent to this contract. 
     */
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {
        // Nothing to do.
    }

    // slither-disable-next-line unused-state,naming-convention
    // solhint-disable-next-line var-name-mixedcase
    uint256[50] private __StakerBFTGap;
}
