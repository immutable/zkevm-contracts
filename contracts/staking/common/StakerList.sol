// Copyright (c) Immutable Pty Ltd 2023
// SPDX-License-Identifier: Apache2
pragma solidity 0.8.19;

/**
 *  @title StakerList
 *  @notice Keeps track of all stakers that have ever staked with this contract
 *  NOTE: Currently NOT designed to be upgradeable.
 */
abstract contract StakerList {
    address[] private allStakers;
    mapping(address => bool) private allStakersMap;

    function addStakerToList(address _staker) internal {
        if (!allStakersMap[_staker]) {
            allStakersMap[_staker] = true;
            allStakers.push(_staker);
        }
    }

    function isStaker(address _possibleStaker) external view returns (bool) {
        return allStakersMap[_possibleStaker];
    }

    function getAllStakers() external view returns (address[] memory) {
        return allStakers;
    }


}
