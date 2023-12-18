// Copyright (c) Immutable Pty Ltd 2018 - 2023
// SPDX-License-Identifier: Apache2
pragma solidity 0.8.19;

import {IValidatorSet} from "../interfaces/common/IValidatorSet.sol";


/**
 * @dev This contract is upgradeable.
 */
contract ValidatorSetBFT is IValidatorSet {
    struct ValidatorInfoBFT {
        // Used for adding and removing stake.
        address stakingAccount;
        // Block number of last block produced by this validator.
        uint256 lastTimeBlockProducer;
        // Initial random commitment value.
        bytes32 initialCommitment;
        // Index into validators array.
        uint256 index;
    }


    error ValidatorNodeAlreadyAdded(address _nodeAccount);
    error StakerForOtherValidator(address _stakingAccount);
    error StakerNotConfigured(address _stakingAccount);
    error MustHaveAtLeastOneValidator(address _stakingAccount);
    error BlockRewardAlreadyPaid(uint256 _blockNumber);

    // Number of blocks per epoch.
    uint256 private constant BLOCKS_PER_EPOCH = 300; 

    // Mapping node validator's node address => Validator Info.
    mapping (address nodeAddress => ValidatorInfoBFT info) public validatorSetByValidatorAccount;

    // Mapping validator's staking account => validator's node address.
    mapping (address => address) public validatorSetByStakingAccount;

    address[] public validators;

    // The last block that block rewards were paid out on. Ensures block rewards are not paid 
    // out twice on the same block.
    uint256 public blockNumberBlockRewardPaidUpTo;

    // Block rewards yet to be paid out.
    mapping (address => uint256) public pendingBlockRewards;




    // TODO only validator controller
    // Staking account same on all chains
    // Node account different on all chains.
    function addValidator(address _nodeAccount, address _stakingAccount, bytes32 _commitment) external {
        if (validatorSetByValidatorAccount[_nodeAccount].stakingAccount != address(0)) {
            revert ValidatorNodeAlreadyAdded(_nodeAccount);
        }
        if (validatorSetByStakingAccount[_stakingAccount] != address(0)) {
            revert StakerForOtherValidator(_stakingAccount);
        }

        ValidatorInfoBFT storage valInfo = validatorSetByValidatorAccount[_nodeAccount];
        valInfo.stakingAccount = _stakingAccount;
        valInfo.lastTimeBlockProducer = block.number;
        valInfo.initialCommitment = _commitment;
        valInfo.index = validators.length;
        validators.push(_nodeAccount);
    }

    // TODO only validator controller.
    function removeValidator(address _stakingAccount) external {
        uint256 numValidators = validators.length;
        if (numValidators == 1) {
            revert MustHaveAtLeastOneValidator(_stakingAccount);
        }

        address nodeAccount = validatorSetByStakingAccount[_stakingAccount];
        if (nodeAccount == address(0)) {
            revert StakerNotConfigured(_stakingAccount);
        }

        validatorSetByStakingAccount[_stakingAccount] = address(0);
        ValidatorInfoBFT storage info = validatorSetByValidatorAccount[nodeAccount];
        info.stakingAccount = address(0);

        uint256 index = info.index;
        if (index != numValidators - 1) {
            validators[index] = validators[numValidators - 1];
        }
        validators.pop();
    }


   function payBlockReward() external {
        if (blockNumberBlockRewardPaidUpTo == block.number) {
            revert BlockRewardAlreadyPaid(block.number);
        }
        // Indicate the block reward has been paid. 
        // Setting this here also acts as re-entrancy protection.
        blockNumberBlockRewardPaidUpTo = block.number;

        // Determine the staker account associated with the validator node account.
        address staker = validatorSetByValidatorAccount[block.coinbase].stakingAccount;

        // Pay the block reward.
        // TODO use the formula
        // TODO handle multi-ERC 20 block rewards
        uint256 amount = 1000;
        pendingBlockRewards[staker] += amount;

        // Update when this validator produced its more recent block.
        validatorSetByValidatorAccount[block.coinbase].lastTimeBlockProducer = block.number;
    }

    // TODO handle multi-ERC 20 block rewards
    function withdrawBlockRewards() external {
        uint256 amount = pendingBlockRewards[msg.sender];
        // Zero before sending to prevent re-entrancy attacks.
        pendingBlockRewards[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }



    function getValidators() override external view returns (address[] memory) {
        return validators;
    }
}
