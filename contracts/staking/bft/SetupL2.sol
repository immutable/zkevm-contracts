// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ChainUtil} from "../common/ChainUtil.sol";
import {StakeController} from "./StakeController.sol";
import {TransparentUpgradeableProxy} from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.so.sol";


// Use this contract to deploy contracts for L2.
// Not upgradeable
contract SetupL2 is ChainUtil {

    error AlreadyDeployed();
    error SpecifyOneOrMoreValidators();

    bool public deployed;

    /**
     * @notice Deploy all of the contracts to set-up the chain on L2, including the validator set and chain control contract for L2.
     */
    function deployAll(address _initialOwner, address[] calldata _validators) external {
        if (!deployed) {
            revert AlreadyDeployed();
        }
        if (_validators.length == 0) {
            revert SpecifyOneOrMoreValidators();
        }

        StakeControllerBFT stakeController = new StakeController();
        bytes stakeControllerParams;
        TransparentUpgradeableProxy stakeControllerProxy = new TransparentUpgradeableProxy(stakeController, _initialOwner, stakeControllerParams);
        StakeControllerBFT stakeController1 = StakeControllerBFT(stakeControllerProxy);

        ValidatorSetBFT validatorSet = new ValidatorSetBFT();
        bytes validatorSetParams;
        TransparentUpgradeableProxy validatorSetProxy = new TransparentUpgradeableProxy(validatorSet, _initialOwner, validatorSetParams);
        ValidatorSetBFT validatorSet1 = ValidatorSetBFT(validatorSetProxy);

        ChainControlBFT chainController = new ValidatorSetBFT();
        bytes chainControllerParams;
        TransparentUpgradeableProxy chainControllerProxy = new TransparentUpgradeableProxy(chainController, _initialOwner, chainControllerParams);
        ChainControlBFT chainController1 = ChainControlBFT(chainControllerProxy);

        uint256 chainId = getChainId();
        stakeController1.registerChain(_stakeController1, chainId);

        for (uint256 i = 0; i < _validators.length; i++) {
            chainController1.addAllowedValidator(_validators[i]);
        }




        deployed = true;
    }
}
