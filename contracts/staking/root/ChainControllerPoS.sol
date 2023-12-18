// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/root/IStakeController.sol";


// Upgradeable
contract ChainController is Initializable {
    IStakeController public stakeController;
    uint256 public chainId;

    mapping (address => bool) public allowedStakingTokens;

    mapping (address => bool) public allowedValidators;


    // slither-disable-next-line naming-convention
    function initializer(address _stakeController, uint256 _chainId) internal onlyInitializing {
        stakeController = IStakeController(_stakeController);
        chainId = _chainId;
    }

    function onInit(uint256 _chainId) external {
        stakeController = IStakeController(_stakeController);
        chainId = _chainId;
    }


    // TODO access control
    function addAllowedStakingToken(address _token) external {
        allowedStakingTokens[_token] = true;
    }

    // TODO access control
    function addValidator(address _validator) external {
        allowedValidators[_validator] = true;
    }

    function isValidStake(address _validator, address /* _staker */, address _token, uint256 /*_amount */) external view returns (bool) {
        return allowedStakingTokens[_token] && allowedValidators[_validator];
    }


    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
