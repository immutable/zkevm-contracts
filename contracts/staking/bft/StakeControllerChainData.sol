// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache 2
pragma solidity 0.8.19;

import {ChainControllerBFT} from "./ChainControllerBFT.sol";

/**
 * @title StakeControllerChainData
 * @notice Holds data to allow look-up between a chain controller contract address and a chain id.
 * Note that this is contract is designed to be included in StakeController. It is upgradeable.
 */
abstract contract StakeControllerChainData {

    error ErrorChainIdAlreadyRegistered(uint256 _chainId);
    error ErrorControlContractAlreadyRegistered(address _controller);

    // Chain id to chain controller contract address.
    mapping(uint256 => ChainControllerBFT) public chainIdToController;
    // TODO is this needed
    // Chain controller contract address to chain id.
    mapping(address => uint256) public controllerToChainId;

    /**
     * @notice Register a chain controller contract.
     * @param _controller Chain manager contract address.
     * @param _chainId Chain id that the chain control contract managers.
     */
    function _registerChild(address _controller, uint256 _chainId) internal {
        if (address(chainIdToController[_chainId]) != address(0)) {
            revert ErrorChainIdAlreadyRegistered(_chainId);
        }
        if (controllerToChainId[_controller] != 0) {
            revert ErrorControlContractAlreadyRegistered(_controller);
        }

        chainIdToController[_chainId] = ChainControllerBFT(_controller);
        controllerToChainId[_controller] = _chainId;
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __StakeControllerChainDataGap;
}
