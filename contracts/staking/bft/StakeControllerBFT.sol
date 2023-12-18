// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IStakeController} from "../interfaces/root/IStakeController.sol";
import {ChainControllerBFT} from "./ChainControllerBFT.sol";
import "./StakeControllerChainData.sol";
import "./ValidatorSetBFT.sol";

contract StakeControllerBFT is IStakeController, Initializable, StakeControllerChainData {
    // TODO should this be passed in at initialisation??. 
    uint256 public constant CHAINID_L2 = 1001;

    ValidatorSetBFT public l2ValidatorSet;

    /**
     * TODO access control
     */
    function registerL3Chain(address _controller, uint256 _chainId) public {
        _registerChild(_controller, _chainId);
        ChainControllerBFT(_controller).onInit(_chainId);
        // slither-disable-next-line reentrancy-events
        emit ChainControllerRegistered(_controller, _chainId);
    }

    function registerL2Chain(address _controller, address _l2ValidatorSet) external {
        registerL3Chain(_controller, CHAINID_L2);
        l2ValidatorSet = ValidatorSetBFT(_l2ValidatorSet);
    }


    function validateOnChain(uint256 _chainId, address _validator, bytes32 _commitment) external override {
        ChainControllerBFT controller = chainIdToController[_chainId];
        if (controller.allowedValidators(_validator)) {
            if (_chainId == CHAINID_L2) {
                l2ValidatorSet.addValidator(_validator, msg.sender, _commitment) ;
            }
            else {
                // Crosschain magic.
            }
        }

    }


    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
