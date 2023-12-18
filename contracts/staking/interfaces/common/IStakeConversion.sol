// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache2
pragma solidity 0.8.19;

interface IStakeConversion {
    function getStakedAmount(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) external view returns (uint256);
}
