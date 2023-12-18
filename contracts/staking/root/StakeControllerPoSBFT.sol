// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/root/staking/IStakeManager.sol";
import "./StakeManagerChildData.sol";
import "./StakeManagerStakingData.sol";

contract StakeManager is IStakeManager, Initializable, StakeManagerChildData, StakeManagerStakingData {
    using SafeERC20 for IERC20;

    IERC20 internal stakingToken;

    function initialize(address newStakingToken) public initializer {
        stakingToken = IERC20(newStakingToken);
    }

    /**
     * TODO access control
     */
    function registerChildChain(address _controller, uint256 _chainId) external {
        id = _registerChild(_controller, _chainId);
        ChainController(_controller).onInit(_chainId);
        // slither-disable-next-line reentrancy-events
        emit ChainControllerRegistered(_controller, _chainId);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function stakeFor(uint256 id, uint256 amount) external {
        require(id != 0 && id <= counter, "StakeManager: INVALID_ID");
        // slither-disable-next-line reentrancy-benign,reentrancy-events
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        // calling the library directly once fixes the coverage issue
        // https://github.com/foundry-rs/foundry/issues/4854#issuecomment-1528897219
        _addStake(msg.sender, id, amount);
        ISupernetManager manager = managerOf(id);
        manager.onStake(msg.sender, amount);
        // slither-disable-next-line reentrancy-events
        emit StakeAdded(id, msg.sender, amount);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function releaseStakeOf(address validator, uint256 amount) external {
        uint256 id = idFor(msg.sender);
        _removeStake(validator, id, amount);
        // slither-disable-next-line reentrancy-events
        emit StakeRemoved(id, validator, amount);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function withdrawStake(address to, uint256 amount) external {
        _withdrawStake(msg.sender, to, amount);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function slashStakeOf(address validator, uint256 amount) external {
        uint256 id = idFor(msg.sender);
        uint256 stake = _stakeOf(validator, id);
        if (amount > stake) amount = stake;
        _removeStake(validator, id, stake);
        _withdrawStake(validator, msg.sender, amount);
        emit StakeRemoved(id, validator, stake);
        emit ValidatorSlashed(id, validator, amount);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function withdrawableStake(address validator) external view returns (uint256 amount) {
        amount = _withdrawableStakeOf(validator);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function totalStake() external view returns (uint256 amount) {
        amount = _totalStake;
    }

    /**
     * @inheritdoc IStakeManager
     */
    function totalStakeOfChild(uint256 id) external view returns (uint256 amount) {
        amount = _totalStakeOfChild(id);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function totalStakeOf(address validator) external view returns (uint256 amount) {
        amount = _totalStakeOf(validator);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function stakeOf(address validator, uint256 id) public view returns (uint256 amount) {
        amount = _stakeOf(validator, id);
    }

    /**
     * @inheritdoc IStakeManager
     */
    function managerOf(uint256 id) public view returns (ISupernetManager manager) {
        manager = ISupernetManager(_managerOf(id));
    }

    /**
     * @inheritdoc IStakeManager
     */
    function idFor(address manager) public view returns (uint256 id) {
        id = _idFor(manager);
    }

    function _withdrawStake(address validator, address to, uint256 amount) private {
        _withdrawStake(validator, amount);
        // slither-disable-next-line reentrancy-events
        stakingToken.safeTransfer(to, amount);
        emit StakeWithdrawn(validator, to, amount);
    }

    // slither-disable-next-line unused-state,naming-convention
    uint256[50] private __gap;
}
