// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache2
pragma solidity 0.8.19;


// Interface for contracts used to select validators 
interface IValidatorSet {
    function getValidators() external view returns (address[] memory);
}
