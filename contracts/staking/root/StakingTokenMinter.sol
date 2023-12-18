// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/root/staking/IERC20MintBurnOnly.sol";
import "../interfaces/root/oracles/IStakeConversion.sol";
import "../interfaces/root/staking/IStakingTokenMinter.sol";
import "../common/AllowedStakingTokens.sol";
import "../common/AllowBlockList.sol";

contract StakingTokenMinter is IStakingTokenMinter, Initializable, AllowedStakingTokens, AllowBlockList {
    IStakeConversion public stakeConversion;
    // @notice Represents stake.
    // @dev address(this) must have minting/burning rights.
    IERC20MintBurnOnly public stakingToken;
    // Token value that the staking tokens are demoninated in.
    // This would be a USD stable coin.
    address public baseStakingToken;

    error MintFailed(uint256 amount);
    error BurnFailed(uint256 amount);


    function initialize(
        address _superAdmin, address _tokenAdmin, address _accountAdmin, 
        address _baseStakingToken,
        address _stakingToken,
        address _stakeConversion
    ) public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _superAdmin);
        _setupRole(ACCOUNT_ADMIN_ROLE, _accountAdmin);
        _setupRole(TOKEN_ADMIN_ROLE, _tokenAdmin);

        baseStakingToken = _baseStakingToken;
        stakingToken = IERC20MintBurnOnly(_stakingToken);
        stakeConversion = IStakeConversion(_stakeConversion);
    }


    function setStakeConversion(address _stakeConversion) external onlyRole(DEFAULT_ADMIN_ROLE) {
        stakeConversion = IStakeConversion(_stakeConversion);
    }

    function setBaseStakingToken(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        baseStakingToken = _token;
    }


    /**
     * @notice Called by a staker contract to mint some staking tokens. 
     * @param _token The token to be staked.
     * @param _amount The number of tokens to be staked.
     * @return The amount of staking tokens minted.
     */
    function mintStakingTokens(
        address _token,
        uint256 _amount
    ) external override onlyAllowedStaker returns (uint256) {
        // Only allow tokens that can be exchanged.
        if (allowedStakingTokens[_token] != StakingTokenMode.Enabled) {
            revert TokenNotAllowed(_token);
        }

        uint256 convertedMintAmount = stakeConversion.getStakingTokenAmount(
            baseStakingToken,
            _token,
            _amount
        );
        if (!stakingToken.mint(msg.sender, convertedMintAmount)) {
            revert MintFailed(convertedMintAmount);
        }
        return convertedMintAmount;
    }

    /**
     * @notice Called by a staker contract to burn some stakign tokens. 
     * @param _amountToBurn Number of staking tokens to burn.
     */
    function burnStakingTokens(
        uint256 _amountToBurn
    ) external override onlyAllowedStaker {
        if (!stakingToken.burn(msg.sender, _amountToBurn)) {
            revert BurnFailed(_amountToBurn);
        }
    }
}



