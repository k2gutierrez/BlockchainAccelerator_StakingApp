// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract StakingApp is Ownable {

    error StakingApp__IncorrectAmountToDeposit();
    error StakingApp__UserAlreadyDepositedTokens();
    error StakingApp__NotStaking();
    error StakingApp__TransferFailed();
    
    // Variables
    address public s_stakingToken;
    uint256 public s_stakingPeriod;
    uint256 public s_fixedStakingAmount;
    uint256 public s_rewardPerPeriod;
    mapping(address user => uint256 tokenAmount) public s_userBalance;
    mapping(address user => uint256 time) public s_elapsedPeriod; 

    // Events
    event ChangeStakingPeriod(uint256 newStakingPeriod);
    event DepositTokens(address userAddress, uint256 depositAmount);
    event WithdrawTokens(address userAddress, uint256 withdrawTokens);
    event EtherSent(uint256 amount);

    // Modifiers

    constructor(address _stakingToken, address _owner, uint256 _stakingPeriod, uint256 _fixedStakingAmount, uint256 _rewardPerPeriod) Ownable(_owner) {
        s_stakingToken = _stakingToken;
        s_stakingPeriod = _stakingPeriod;
        s_fixedStakingAmount = _fixedStakingAmount;
        s_rewardPerPeriod = _rewardPerPeriod;
    }

    function depositTokens(uint256 _tokenAmountToDeposit) external {
        if (_tokenAmountToDeposit != s_fixedStakingAmount) revert StakingApp__IncorrectAmountToDeposit();
        if (s_userBalance[msg.sender] != 0) revert StakingApp__UserAlreadyDepositedTokens();
        IERC20(s_stakingToken).transferFrom(msg.sender, address(this), _tokenAmountToDeposit);
        s_userBalance[msg.sender] += _tokenAmountToDeposit;
        s_elapsedPeriod[msg.sender] = block.timestamp;
        emit DepositTokens(msg.sender, _tokenAmountToDeposit);
    }

    function withdrawTokens() external {
        uint256 userBalance = s_userBalance[msg.sender];
        s_userBalance[msg.sender] = 0;
        IERC20(s_stakingToken).transfer(msg.sender, userBalance);
        emit WithdrawTokens(msg.sender, userBalance);
    }

    function claimRewards() external {
        // 1. Check Balance
        if (s_userBalance[msg.sender] != s_fixedStakingAmount) revert StakingApp__NotStaking();
        // 2. Calculate reward amount
        uint256 elapsePeriod = block.timestamp - s_elapsedPeriod[msg.sender];
        require(elapsePeriod >= s_stakingPeriod, "Need to wait!");

        // 3. Update state
        s_elapsedPeriod[msg.sender] = block.timestamp;

        // 4. Transfer rewards
        (bool success,) = msg.sender.call{value: s_rewardPerPeriod}("");
        if (!success) revert StakingApp__TransferFailed();
    }

    function changeStakingPeriod(uint256 _newStakingPeriod) external onlyOwner {
        s_stakingPeriod = _newStakingPeriod;
        emit ChangeStakingPeriod(_newStakingPeriod);
    }

    // function feedContract() external payable onlyOwner {}
    receive() external payable onlyOwner {
        emit EtherSent(msg.value);
    }
    
}
