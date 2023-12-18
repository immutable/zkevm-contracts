// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache2
pragma solidity 0.8.19;


interface IStakeController {

    event ChainControllerRegistered(address _controller, uint256 _chainId);

    function validateOnChain(uint256 _chainId, address _validator, bytes32 _commitment) external;
}