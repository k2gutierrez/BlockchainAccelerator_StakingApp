// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Test, console2 } from "forge-std/Test.sol";
import { StakingToken } from "../src/StakingToken.sol";
import { StakingApp } from "../src/StakingApp.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakingAppTest is Test {

    // Contracts variables
    StakingToken stakingToken;
    StakingApp stakingApp;

    // StakingToken parameters
    string _name = "Staking Token";
    string _symbol = "STK";

    // StakingApp parameters
    address _owner = vm.addr(1);
    uint256 _stakingPeriod = 1000000000000;
    uint256 _fixedStakingAmount = 10;
    uint256 _rewardPeriod = 1 ether;

    uint256 balanceForUsers = 10 ether;
    address randomUser = makeAddr("USER1");

    function setUp() external {
        stakingToken = new StakingToken(_name, _symbol);
        stakingApp = new StakingApp(address(stakingToken), _owner, _stakingPeriod, _fixedStakingAmount, _rewardPeriod);
        vm.deal(_owner, balanceForUsers);
        vm.deal(randomUser, balanceForUsers);
    }

    // Testing deployed functions
    function testStakingTokenCorrectlyDeployed() external view {
        assert(address(stakingToken) != address(0));
    }

    function testStakingAppCorrectlyDeployed() external view {
        assert(address(stakingApp) != address(0));
    }

    // Testing Owner functions

    // Owner// Changing Staking period
    function testShouldRevertNotOwner() external {
        uint256 newStakingPeriod = 1;
        vm.expectRevert();
        stakingApp.changeStakingPeriod(newStakingPeriod);
    }

    function testChangeStakingPeriod() external {
        vm.startPrank(_owner);
        uint256 newStakingPeriod = 1;

        uint256 stakingPeriodBefore = stakingApp.s_stakingPeriod();
        stakingApp.changeStakingPeriod(newStakingPeriod);
        uint256 stakingPeriodAfter = stakingApp.s_stakingPeriod();

        assertNotEq(stakingPeriodBefore, stakingPeriodAfter);
        assertEq(newStakingPeriod, stakingPeriodAfter);

        vm.stopPrank();
    }

    // Owner// Sending Ether to contract
    function testContractReceivesEtherCorrectly() external {
        vm.startPrank(_owner);
        uint256 etherValue = 1 ether;
        uint256 balanceBefore = address(stakingApp).balance;
        (bool success,) = address(stakingApp).call{value: etherValue}("");
        require(success, "Transfer Failed!");
        uint256 balanceAfter = address(stakingApp).balance;
        vm.stopPrank();

        assert(balanceAfter - balanceBefore == etherValue);
    }

    function testContractRevertsOnReceivingEtherNoOwner() external {
        vm.startPrank(randomUser);
        uint256 etherValue = 1 ether;
        vm.expectRevert();
        (bool success,) = address(stakingApp).call{value: etherValue}("");
        require(success, "Transfer Failed!");
        vm.stopPrank();
    }

    // Testing Deposit function
    function testDepositRevertsIncorrectStakingAmount() external {
        uint256 amountOfTokensToMint = 8;
        uint256 amountToDeposit = amountOfTokensToMint;
        vm.startPrank(randomUser);
        stakingToken.mint(amountOfTokensToMint);
        IERC20(address(stakingToken)).approve(address(stakingApp), amountToDeposit);
        vm.expectRevert(StakingApp.StakingApp__IncorrectAmountToDeposit.selector);
        stakingApp.depositTokens(amountToDeposit);
        vm.stopPrank();
    }

    function testDepositRevertsAlreadyStakedTokens() external {
        uint256 amountOfTokensToMint = 20;
        uint256 amountToDeposit = stakingApp.s_fixedStakingAmount();
        vm.startPrank(randomUser);
        stakingToken.mint(amountOfTokensToMint);
        IERC20(stakingToken).approve(address(stakingApp), amountOfTokensToMint);
        stakingApp.depositTokens(amountToDeposit);
        vm.expectRevert(StakingApp.StakingApp__UserAlreadyDepositedTokens.selector);
        stakingApp.depositTokens(amountToDeposit);
        vm.stopPrank();
    }

    function testDepositTokens() external {
        uint256 amountOfTokensToMint = 20;
        uint256 amountToDeposit = 10;
        vm.startPrank(randomUser);
        uint256 balanceBefore = stakingApp.s_userBalance(randomUser);
        uint256 elapsedPeriodBefore = stakingApp.s_elapsedPeriod(randomUser);
        stakingToken.mint(amountOfTokensToMint);
        uint256 balanceAfterMint = IERC20(address(stakingToken)).balanceOf(randomUser);
        IERC20(stakingToken).approve(address(stakingApp), amountToDeposit);
        stakingApp.depositTokens(amountToDeposit);
        uint256 balanceAfterDeposit = stakingApp.s_userBalance(randomUser);
        uint256 elapsedPeriodAfter = stakingApp.s_elapsedPeriod(randomUser);
        vm.stopPrank();

        assert(elapsedPeriodBefore == 0);
        assert(elapsedPeriodAfter == block.timestamp);
        assertEq(amountOfTokensToMint, balanceAfterMint);
        assertNotEq(balanceBefore, balanceAfterDeposit);
        assert(balanceAfterDeposit == amountOfTokensToMint - amountToDeposit);
    }

    // Testing Withdraw function
    function testCanOnlyWithdraw0WithoutDeposit() external {
        vm.startPrank(randomUser);
        uint256 userBalanceBefore = stakingApp.s_userBalance(randomUser);
        stakingApp.withdrawTokens();
        uint256 userBalanceAfter = stakingApp.s_userBalance(randomUser);
        vm.stopPrank();

        assert(userBalanceBefore == userBalanceAfter);
    }

    function testWithdrawTokenCorrectly() external {
        vm.startPrank(randomUser);

        uint256 tokenAmount = stakingApp.s_fixedStakingAmount();
        stakingToken.mint(tokenAmount);

        uint256 userBalanceBefore = stakingApp.s_userBalance(randomUser);
        uint256 elapsePeriodBefore = stakingApp.s_elapsedPeriod(randomUser);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        uint256 userBalanceAfter = stakingApp.s_userBalance(randomUser);
        uint256 elapsePeriodAfter = stakingApp.s_elapsedPeriod(randomUser);

        assert(userBalanceAfter - userBalanceBefore == tokenAmount);
        assert(elapsePeriodBefore == 0);
        assert(elapsePeriodAfter == block.timestamp);

        uint256 userBalanceBefore2 =  IERC20(stakingToken).balanceOf(randomUser);
        uint256 userBalanceBeforeInMapping = stakingApp.s_userBalance(randomUser);
        stakingApp.withdrawTokens();
        uint256 userBalanceAfterInMapping = stakingApp.s_userBalance(randomUser);
        uint256 userBalanceAfter2 = IERC20(stakingToken).balanceOf(randomUser);

        assert(userBalanceAfter2 == userBalanceBefore2 + userBalanceBeforeInMapping);
        assert(userBalanceAfterInMapping == 0);

        vm.stopPrank();
    
    }

    // Testing Claim rewards function
    function testCannotClaimIfNotStaking() external {
        vm.startPrank(randomUser);
        vm.expectRevert(StakingApp.StakingApp__NotStaking.selector);
        stakingApp.claimRewards();
        vm.stopPrank();
    }

    function testCannotClaimSatkingElapsedPeriodNotFullfilled() external {
        uint256 etherValue = _rewardPeriod;
        vm.prank(_owner);
        (bool success,) = address(stakingApp).call{value: etherValue}("");
        require(success, "Tranfer Failed!");

        uint256 tokenAmount = stakingApp.s_fixedStakingAmount();
        vm.startPrank(randomUser);
        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        vm.warp(block.timestamp + stakingApp.s_stakingPeriod() - 1);
        vm.expectRevert("Need to wait!");
        stakingApp.claimRewards();
        vm.stopPrank();
    }

    function testCannotClaimRevertsNoEther() external {

        uint256 tokenAmount = stakingApp.s_fixedStakingAmount();
        vm.startPrank(randomUser);
        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        vm.warp(block.timestamp + stakingApp.s_stakingPeriod());
        vm.expectRevert(StakingApp.StakingApp__TransferFailed.selector);
        stakingApp.claimRewards();
        vm.stopPrank();
    }

    function testCanClaimRewards() external {
        uint256 etherValue = stakingApp.s_rewardPerPeriod();
        vm.prank(_owner);
        (bool success,) = address(stakingApp).call{value: etherValue}("");
        require(success, "Tranfer Failed!");

        uint256 contractEthBalanceBefore = address(stakingApp).balance;

        uint256 tokenAmount = stakingApp.s_fixedStakingAmount();
        vm.startPrank(randomUser);
        uint256 ethBalanceBefore = address(randomUser).balance;
        stakingToken.mint(tokenAmount);
        IERC20(stakingToken).approve(address(stakingApp), tokenAmount);
        stakingApp.depositTokens(tokenAmount);
        vm.warp(block.timestamp + stakingApp.s_stakingPeriod());
        stakingApp.claimRewards();
        uint256 ethBalanceAfter = address(randomUser).balance;
        uint256 contractEthBalanceAfter = address(stakingApp).balance;
        uint256 elapseTimePeriod = stakingApp.s_elapsedPeriod(randomUser);
        vm.stopPrank();
        
        

        console2.log("User Balance after:", ethBalanceAfter);
        assert(contractEthBalanceBefore == etherValue);
        assertNotEq(ethBalanceBefore, ethBalanceAfter);
        assert(ethBalanceAfter == etherValue + balanceForUsers);
        assertNotEq(contractEthBalanceBefore, contractEthBalanceAfter);
        assert(contractEthBalanceAfter == 0);
        assert(elapseTimePeriod == block.timestamp);
    }

}