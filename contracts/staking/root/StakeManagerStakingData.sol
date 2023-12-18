// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title StakeManagerStakingData
 * @notice Holds all staking related data.
 * Note that this is contract is designed to be included in StakeManager. It is upgradeable.
 */
abstract contract StakeManagerStakingData {
    // slither-disable-next-line naming-convention
    uint256 internal _totalStake;
    // validator => child => amount
    mapping(address => mapping(uint256 => uint256)) private _stakes;
    // child chain id => total stake
    mapping(uint256 => uint256) private _totalStakePerChild;
    // validator address => stake across all child chains.
    mapping(address => uint256) private _totalStakes;
    // validator address => withdrawable stake.
    mapping(address => uint256) private _withdrawableStakes;

    function _addStake(address validator, uint256 id, uint256 amount) internal {
        _stakes[validator][id] += amount;
        _totalStakePerChild[id] += amount;
        _totalStakes[validator] += amount;
        _totalStake += amount;
    }

    function _removeStake(address validator, uint256 id, uint256 amount) internal {
        _stakes[validator][id] -= amount;
        _totalStakePerChild[id] -= amount;
        _totalStakes[validator] -= amount;
        _totalStake -= amount;
        _withdrawableStakes[validator] += amount;
    }

    function _withdrawStake(address validator, uint256 amount) internal {
        _withdrawableStakes[validator] -= amount;
    }

    function _withdrawableStakeOf(address validator) internal view returns (uint256 amount) {
        amount = _withdrawableStakes[validator];
    }

    function _totalStakeOfChild(uint256 id) internal view returns (uint256 amount) {
        amount = _totalStakePerChild[id];
    }

    function _stakeOf(address validator, uint256 id) internal view returns (uint256 amount) {
        amount = _stakes[validator][id];
    }

    function _totalStakeOf(address validator) internal view returns (uint256 amount) {
        amount = _totalStakes[validator];
    }

    // Storage gap
    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
