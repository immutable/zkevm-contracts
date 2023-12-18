// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title Stake Queues
 * @notice Queue of stake that stakers have added.
 * @dev Not designed to be upgradeable.
 */
abstract contract StakeQueues {
    uint256 private constant MAX_NUM_TOKENS = 10;

    struct StakeInfo {
        address token; // Token used by staker for staking.
        uint256 tokenAmount; // Amount of staker's tokens.
        uint256 stakingTokenAmount; // Amount of Staking Tokens that the tokenAmount corresponds to.
    }
    struct StakeQueue {
        uint256 tail; // Tail of the queue.
        uint256 head; // Head of the queue.
        mapping(uint256 => StakeInfo) queue; // Mapping queue index => stake
    }
    // Map: staker address => queue
    mapping(address => StakeQueue) private stakeQueues;

    error NoStakeInQueue(address _staker);

    /**
     * @notice Add stake to the stake queue.
     *
     * @param _staker The address staking value.
     * @param _token The token being staked.
     * @param _tokenAmount The number of tokens being staked.
     * @param _stakingTokenAmount The number of staking tokens that correspond to _tokenAmount
     *          given the current exchange rate.
     */
    function addStakeToQueue(
        address _staker,
        address _token,
        uint256 _tokenAmount,
        uint256 _stakingTokenAmount
    ) internal {
        uint256 tail = stakeQueues[_staker].tail;
        stakeQueues[_staker].queue[tail] = StakeInfo(_token, _tokenAmount, _stakingTokenAmount);
        stakeQueues[_staker].tail++;
    }

    /**
     * @notice Remove stake from a staker. Either the requested amount will be removed,
     *          or if the requested amount exceeds the staker's balance, then remove all
     *          of the balance.
     * @dev    If the number of token types the staker has staked exceeds MAX_NUM_TOKENS,
     *          then only tokens for MAX_NUM_TOKENS will be removed.
     * @param _staker The staker to remove stake for.
     * @param _stakingTokenAmount The number of staking tokens to remove.
     */
    function removeStakeFromQueue(
        address _staker,
        uint256 _stakingTokenAmount
    ) internal returns (address[] memory, uint256[] memory, uint256) {
        uint256 head = stakeQueues[_staker].head;
        uint256 tail = stakeQueues[_staker].tail;

        address[] memory tokens = new address[](MAX_NUM_TOKENS);
        uint256[] memory amounts = new uint256[](MAX_NUM_TOKENS);

        uint256 amountWithdrawn = 0;
        while (head != tail && amountWithdrawn < _stakingTokenAmount) {
            StakeInfo storage stakerInfo = stakeQueues[_staker].queue[head];
            uint256 stakingTokenAmount = stakerInfo.stakingTokenAmount;

            uint256 amountToWithdraw = _stakingTokenAmount - amountWithdrawn;
            if (amountToWithdraw >= stakingTokenAmount) {
                bool failedToAdd = addToArray(tokens, amounts, stakerInfo.token, stakerInfo.tokenAmount);
                if (failedToAdd) {
                    //TODO emit an event
                    break;
                }
                head++;
                amountWithdrawn += stakingTokenAmount;
            } else {
                // TODO if this overflows, a panic will be raised. It would be good to detect this possibility and revert with a better error message: withdraw less
                uint256 tokenAmountToWithdraw = (amountToWithdraw * stakerInfo.tokenAmount) / stakingTokenAmount;
                bool failedToAdd = addToArray(tokens, amounts, stakerInfo.token, tokenAmountToWithdraw);
                if (failedToAdd) {
                    //TODO emit an event
                    break;
                }
                stakerInfo.tokenAmount -= tokenAmountToWithdraw;
                stakerInfo.stakingTokenAmount = stakingTokenAmount - amountToWithdraw;
                // If only part of the amount needed, then there is no need to go around in the loop again
                break;
            }
        }
        stakeQueues[_staker].head = head;

        (address[] memory rTokens, uint256[] memory rAmounts) = resizeArrays(tokens, amounts);
        return (rTokens, rAmounts, amountWithdrawn);
    }

    /**
     * @notice For a given staker, return the number of tokens of various types staked.
     * @param _staker The staker to determine information about.
     * @return an array of token addresses and an array of corresponding amounts.
     */
    function amountStaked(address _staker) external view returns (address[] memory, uint256[] memory) {
        uint256 head = stakeQueues[_staker].head;
        uint256 tail = stakeQueues[_staker].tail;

        address[] memory tokens = new address[](MAX_NUM_TOKENS);
        uint256[] memory amounts = new uint256[](MAX_NUM_TOKENS);

        while (head != tail) {
            address token = stakeQueues[_staker].queue[head].token;
            uint256 tokenAmount = stakeQueues[_staker].queue[head].tokenAmount;
            bool failedToAdd = addToArray(tokens, amounts, token, tokenAmount);
            if (failedToAdd) {
                // TODO: can't emit an event in a view.
                break;
            }
            head++;
        }
        return resizeArrays(tokens, amounts);
    }

    /**
     * @notice For a given staker, return the number of staking tokens staked.
     * @param _staker The staker to determine information about.
     * @return the number of staking tokens staked
     */
    function amountStakingTokensStaked(address _staker) public view returns (uint256) {
        uint256 head = stakeQueues[_staker].head;
        uint256 tail = stakeQueues[_staker].tail;

        uint256 total;
        while (head != tail) {
            total += stakeQueues[_staker].queue[head].stakingTokenAmount;
            head++;
        }
        return total;
    }


    /**
     * @notice Determine the tokens used by a set of stakers.
     * @param _stakers The staker to determine information about.
     * @return an array of token addresses.
     */
    function getTokensUsed(address[] memory _stakers) public view returns (address[] memory) {
        address[] memory tokens = new address[](MAX_NUM_TOKENS);
        for (uint256 i = 0; i < _stakers.length; i++) {
            uint256 head = stakeQueues[_stakers[i]].head;
            uint256 tail = stakeQueues[_stakers[i]].tail;
            while (head != tail) {
                address token = stakeQueues[_stakers[i]].queue[head].token;
                bool failedToAdd = addToAddressArray(tokens, token);
                if (failedToAdd) {
                    // TODO: can't emit an event in a view.
                    break;
                }
                head++;
            }
        }
        return resizeAddressArray(tokens);
    }

    /**
     * Add a token and amount to the arrays. If the token has already been staked, add the amount to the
     * existing entry in the array.
     * @return true if failed to add the token and amount to the array.
     */
    function addToArray(
        address[] memory _tokens,
        uint256[] memory _amounts,
        address _token,
        uint256 _tokenAmount
    ) private pure returns (bool) {
        for (uint256 i = 0; i < MAX_NUM_TOKENS; i++) {
            // The token isn't in the array yet, add it.
            if (_tokens[i] == address(0)) {
                _tokens[i] = _token;
                _amounts[i] = _tokenAmount;
                return false;
            }
            // The token is in the array, increase the amount
            if (_tokens[i] == _token) {
                _amounts[i] += _tokenAmount;
                return false;
            }
            // Otherwise, token[i] is another token, loop around again to try the next index in the array
        }
        return true;
    }

    /**
     * @notice Resize the fixed length arrays of tokens and amounts to ones that
     *          that match the number of entries in the arrays.
     * @param _tokens Array of token addresses.
     * @param _amounts Array of amounts corresponding to tokens.
     * @return Arrays of tokens and amounts, with unused array indices removed.
     */
    function resizeArrays(
        address[] memory _tokens,
        uint256[] memory _amounts
    ) private pure returns (address[] memory, uint256[] memory) {
        uint256 size = 0;
        for (size = 0; size < MAX_NUM_TOKENS; size++) {
            if (_tokens[size] == address(0)) {
                break;
            }
        }
        address[] memory tokens = new address[](size);
        uint256[] memory amounts = new uint256[](size);
        for (uint256 i = 0; i < size; i++) {
            tokens[i] = _tokens[i];
            amounts[i] = _amounts[i];
        }
        return (tokens, amounts);
    }

    /**
     * Add a token to the array.
     * @return true if failed to add the token and amount to the array.
     */
    function addToAddressArray(address[] memory _tokens, address _token) private pure returns (bool) {
        for (uint256 i = 0; i < MAX_NUM_TOKENS; i++) {
            // The token isn't in the array yet, add it.
            if (_tokens[i] == address(0)) {
                _tokens[i] = _token;
                return false;
            }
            // The token is in the array
            if (_tokens[i] == _token) {
                return false;
            }
            // Otherwise, token[i] is another token, loop around again to try the next index in the array
        }
        return true;
    }

    /**
     * @notice Resize the fixed length array of tokens to one
     *          that match the number of entries in the array.
     * @param _tokens Array of token addresses.
     * @return Arrays of tokens and amounts, with unused array indices removed.
     */
    function resizeAddressArray(address[] memory _tokens) private pure returns (address[] memory) {
        uint256 size = 0;
        for (size = 0; size < MAX_NUM_TOKENS; size++) {
            if (_tokens[size] == address(0)) {
                break;
            }
        }
        address[] memory tokens = new address[](size);
        for (uint256 i = 0; i < size; i++) {
            tokens[i] = _tokens[i];
        }
        return tokens;
    }
}
