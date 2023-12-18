// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/root/IStakeController.sol";


// Upgradeable
contract ChainControllerBFT is Initializable {

    error AlreadyConfigured();

    address public stakeController;
    uint256 public chainId;
    bool public configured;


    mapping (address => bool) public allowedValidators;


    function onInit(uint256 _chainId) external {
        if (configured) {
            revert AlreadyConfigured();
        }
        stakeController = msg.sender;
        chainId = _chainId;
    }


    // TODO access control
    function addAllowedValidator(address _validator) external {
        allowedValidators[_validator] = true;
    }

    // TODO access control
    function removeAllowedValidator(address _validator) external {
        allowedValidators[_validator] = false;
    }


    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __ChainControllerBFTGap;
}
