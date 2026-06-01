// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {StakingToken} from "../src/StakingToken.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract StakingTokenTest is Test {
    StakingToken public stakingToken;
    string name = "Staking Token";
    string symbol = "STK";

    address user1 = makeAddr("user1");

    function setUp() public {
        stakingToken = new StakingToken(name, symbol);
    }

    function testStakingTokenMintsCorrectly() public {
        uint256 amount = 1 ether;
        
        vm.startPrank(user1);
        uint256 balanceBefore = IERC20(address(stakingToken)).balanceOf(user1);
        stakingToken.mint(amount);

        uint256 balanceAfter = IERC20(address(stakingToken)).balanceOf(user1);
        vm.stopPrank();
        assert(balanceAfter - balanceBefore == amount);
        assertNotEq(balanceBefore, balanceAfter);
    }

}
