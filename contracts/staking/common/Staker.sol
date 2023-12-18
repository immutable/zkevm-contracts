// Copyright (c) Immutable Pty Ltd 2023
// SPDX-License-Identifier: Apache2
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/root/staking/IStakingTokenMinter.sol";

import "./AllowBlockList.sol";
import "./AllowedStakingTokens.sol";
import "./ChainUtil.sol";
import "./StakerList.sol";
import "./StakeQueues.sol";

    struct StakerInit {
        address superAdmin; 
        address tokenAdmin;
        address accountAdmin;
        address validator;          // Address of the staker that is operating the validator node on the child chain.
        address stakingTokenMinter;      
        address stakingToken;
        address stakeManager;
        uint256 ethereumChainId;    // Chain id of the root chain. This will be either Ethereum (1) or a test net chain id.
        uint256 childChainId;       // Child chain to stake with.
        address exitHelper;
    }


/**
 * @title Staker
 * @notice Holds stake for a validator. From the perspective of the staking system, 
 *         this contract is the validator.
 * @dev This contract is NOT upgradeable. If there is an issue, the solution is to deploy a 
 *      new Staker contract, remove stake from this contract and start using the other contract.
 *
 *  In the code below, the term Child Chain means Immutable zkEVM or Immutable App Chain.
 */
contract Staker is ChainUtil, AllowedStakingTokens, AllowBlockList, StakeQueues, StakerList {

    bytes32 private constant WITHDRAW_SIG = keccak256("WITHDRAW");



    // Address of the staker that is operating the validator node on the child chain.
    address public validator;

    // Address of stake manager. 
    IStakeManager public stakeManager;

    // Address of contract that will mint staking tokens.
    IStakingTokenMinter public stakingTokenMinter;

    address public exitHelper;

    // Child chain that this validator is staking with.
    uint256 public childChainId;

    // Token used for staking with stake manager.
    IERC20 public stakingToken;

    // Number of staking tokens that the staker has withdrawn on L2 
    // that have not been withdrawn on L1.
    mapping (address => uint256) public withdrawable;

    // The total amount of staking tokens that this Staker has under its control, 
    // assuming it has not been slashed. This will equal the sum of:
    // * Amount that has been slashed.
    // * Amount staked with the Stake Manager.
    // * Amount withdrawable with the Stake Manager.
    // * Number of staking tokens held by this contract.
    uint256 totalStakedNoSlashing;


    error Unauthorized(string message);


    event WithdrawStakeStatus(address _staker, uint256 _withdrawableStake, uint256 _withdrawnOnL2, uint256 _numStakingTokens, uint256 _requested);


    /**
     *
     * @param _initParams Object containing initialization parameters.
     */
    constructor(
        StakerInit memory _initParams
    ) ChainUtil(_initParams.ethereumChainId) {
        _setupRole(DEFAULT_ADMIN_ROLE, _initParams.superAdmin);
        _setupRole(ACCOUNT_ADMIN_ROLE, _initParams.accountAdmin);
        _setupRole(TOKEN_ADMIN_ROLE, _initParams.tokenAdmin);

        validator = _initParams.validator;
        stakingTokenMinter = IStakingTokenMinter(_initParams.stakingTokenMinter);
        stakingToken = IERC20(_initParams.stakingToken);
        stakeManager = IStakeManager(_initParams.stakeManager);
        childChainId = _initParams.childChainId;
        exitHelper = _initParams.exitHelper;
    }

    /**
     * @notice Add one or more tokens to the list of tokens that can be staked with this validator.
     * NOTE: Access control done in super.
     * @param _tokens Array of tokens to add to the supported list.
     */
    function addAllowedStakingTokens(address[] calldata _tokens) public override {
        super.addAllowedStakingTokens(_tokens);

        // TODO Ask the stake manager if the new token(s) will be acceptable, given the
        // chain that this validator is currently staking for.
    }


    function stake(address _token, uint256 _amount) external onlyOnEthereum {
        if (!isAllowed(msg.sender)) {
            revert NotAllowed(msg.sender);
        }
        if (allowedStakingTokens[_token] != StakingTokenMode.Enabled) {
            revert TokenNotAllowed(_token);
        }

        // Transfer the token being staked to the Staker contract. 
        // slither-disable-next-line reentrancy-benign,reentrancy-events
        //        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        uint256 stakingTokenAmount = stakingTokenMinter.mintStakingTokens(_token, _amount);

        bytes memory metaData = abi.encodePacked(msg.sender, stakingTokenAmount);

        // TODO pass in metaData
        stakeManager.stakeFor(childChainId, stakingTokenAmount);

        // Record the amount of stake that has been staked.
        addStakeToQueue(msg.sender, _token, _amount, stakingTokenAmount);

        // Add the staker to the list of all stakers that have ever staked here.
        addStakerToList(msg.sender);

        totalStakedNoSlashing += stakingTokenAmount;
    }



// TODO needs to be pausable

    function withdrawUpTo(uint256 _amount) external onlyOnEthereum {
        // Multiple stakers may be wishing to unstake at the same time. As such, 
        // as a start, withdraw all withdrawable stake in the stake manager.
        uint256 withdrawableStake = stakeManager.withdrawableStake(msg.sender);
        if (withdrawableStake > 0) {
            stakeManager.withdrawStake(address(this), withdrawableStake);
        }

        // The real withdrawable stake is the number of staking tokens this contract has.
        withdrawableStake = stakingToken.balanceOf(address(this));

        uint256 stakeInStakingManager = stakeManager.stakeOf(msg.sender, childChainId);

        uint256 amountSlashed = totalStakedNoSlashing - stakeInStakingManager - withdrawableStake;
        if (amountSlashed != 0) {
            haltDeposits = true;
        }


        // However, a staker is limited to the number of tokens they have withdrawn on L2.
        uint256 withdrawnOnL2 = withdrawable[msg.sender];

        // As a safety check, ensure that somehow withdrawnOnL2 is not more than the 
        // number of tokens staked.
        uint256 numStakingTokens = amountStakingTokensStaked(msg.sender);
        emit WithdrawStakeStatus(msg.sender, withdrawableStake, withdrawnOnL2, numStakingTokens, _amount);
        uint256 numToWithdraw = withdrawnOnL2;
        if (numStakingTokens < withdrawnOnL2) {
            numToWithdraw = numStakingTokens;
        }
        // We are limited to the number of tokens that have been withdrawn to the stake manager.
        if (withdrawableStake < numToWithdraw) {
            numToWithdraw = withdrawableStake;
        }

        // The final limitation is how many tokens the user wants to withdraw.
        if (_amount < numToWithdraw) {
            numToWithdraw = _amount;
        }

        // Withdraw tokens from staking queue in order that they tokens were first staked. 
        // If there are more types of tokens than can be unstaked in one go, then the amount
        // actually unstaked will be less than that which was requested.
        (address[] memory tokens, uint256[] memory amounts, uint256 amountRemoved) = removeStakeFromQueue(msg.sender, numToWithdraw);

        // Remove the staking tokens 
        withdrawable[msg.sender] -= amountRemoved;
        stakingTokenMinter.burnStakingTokens(amountRemoved);
        totalStakedNoSlashing -= amountRemoved;

        // Distribute the originally staked tokens.
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).transfer(msg.sender, amounts[i]);
        }
    }


    /**
     */
    function onL2StateReceive(uint256 /*id*/, address sender, bytes calldata data) external {
        if (msg.sender != exitHelper || sender != address(this)) revert Unauthorized("exitHelper");
        if (bytes32(data[:32]) == WITHDRAW_SIG) {
            (address staker, uint256 amount) = abi.decode(data[32:], (address, uint256));
            withdrawable[staker] += amount;
        }
    }


}
