// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Staking token
 * @author Carlos Gutiérrez
 * @notice Staking token ERC20
 */
contract StakingToken is ERC20 {
    
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    /**
     * @dev mint function
     * @param _amount amount to mint
     */
    function mint(uint256 _amount) external {
        _mint(msg.sender, _amount);
    }
    
}
