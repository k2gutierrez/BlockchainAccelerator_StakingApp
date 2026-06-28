<div align="center">
  <h1>🥩 Fixed-Yield Staking Application</h1>
  <p><b>A robust DeFi staking layer with time-locked ERC20 deposits and native ETH rewards</b></p>
</div>

## 📖 About the Project

The **Fixed-Yield Staking Application** is a production-ready Web3 Smart Contract project built with **Solidity** and thoroughly tested using the **Foundry** framework. At its core, the project provides a secure mechanism for users to stake a specific ERC20 token and earn fixed rewards in native Ether (ETH) over predefined time periods.

This architecture is ideal for DAOs, decentralized protocols, or Web3 startups looking to incentivize token holding and reduce market circulation by rewarding loyal community members directly from a project treasury.

**Key Technical Highlights:**
* **Solidity `^0.8.30`:** Leveraging up-to-date compiler features for maximum security and gas efficiency.
* **OpenZeppelin Contracts:** Utilizing standard `IERC20` and `Ownable` implementations to prevent common attack vectors and handle secure access control.
* **Foundry Framework:** Complete with high-speed fuzz testing, state assertions, and comprehensive coverage.
* **Strict State Management:** Enforces fixed deposit amounts and strict time-locks to prevent reward manipulation.

---

## ⚙️ How It Works

The `StakingApp` contract requires users to deposit an exact, predefined amount of a specific ERC20 token (`StakingToken`). Once deposited, a time-lock initiates. If the user maintains their stake for the entire duration of the `stakingPeriod`, they become eligible to claim a fixed ETH reward. Users retain full custody of their principal and can withdraw their initial tokens at any time, though doing so prematurely forfeits uncompleted reward cycles.

### Architecture Diagram

![Project Diagram](./images/diagram.png)

[StakingApp.sol](./src/StakingApp.sol) - Main Application Logic

[StakingToken.sol](./src/StakingToken.sol) - ERC20 Token Mock to apply in StakingApp.sol

# 💻 Technical Docs
The primary interaction points of the application handle deposits, withdrawals, and reward claims. The contract strictly manages state to prevent reentrancy and double-claiming.

## depositTokens
Users deposit the required fixed amount of tokens. Reverts if the user has already deposited or if the amount is incorrect.

```Solidity
    function depositTokens(uint256 _tokenAmountToDeposit) external {
        if (_tokenAmountToDeposit != s_fixedStakingAmount) revert StakingApp__IncorrectAmountToDeposit();
        if (s_userBalance[msg.sender] != 0) revert StakingApp__UserAlreadyDepositedTokens();
        
        IERC20(s_stakingToken).transferFrom(msg.sender, address(this), _tokenAmountToDeposit);
        
        s_userBalance[msg.sender] += _tokenAmountToDeposit;
        s_elapsedPeriod[msg.sender] = block.timestamp;
        
        emit DepositTokens(msg.sender, _tokenAmountToDeposit);
    }
```

## claimRewards
Calculates if the user has waited the required staking period. If successful, resets the timer and transfers the ETH reward.

```Solidity
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
```

🚀 Execution Example
Here is a step-by-step example of how a user interacts with the StakingApp to earn ETH.

- Step 1: Setup & Funding
The contract is deployed by the Owner. During deployment, the Staking Token address, staking period (e.g., 7 days), fixed staking amount (e.g., 100 STK), and reward per period (e.g., 0.1 ETH) are configured. The Owner sends ETH directly to the contract to fund the reward pool.

- Step 2: User Approval
The User wants to stake. Because the staking token is an ERC20 standard token, the user must first call approve() on the token contract directly, granting the StakingApp contract permission to move their 100 STK.

- Step 3: Execute Deposit
The user calls depositTokens(100) on the StakingApp. The contract pulls the 100 STK into its vault and records the current block.timestamp.

- Step 4: Claiming Rewards
After 7 days pass, the user calls claimRewards(). The contract checks that the user still has 100 STK deposited and that 7 days have elapsed. It then sends 0.1 ETH to the user and resets their timestamp so they can earn another 0.1 ETH in exactly 7 more days.

- Step 5: Withdrawal
The user decides to exit the pool. They call withdrawTokens(). The contract zeroes out their balance and returns their 100 STK. Because their balance is now 0, they can no longer claim ETH rewards.

⬆️ Installation
```Bash
forge install OpenZeppelin/openzeppelin-contracts foundry-rs/forge-std
```

🧪 Testing
```Bash
- forge test -vvvv
```

📊 Coverage
```Bash
- forge coverage
```

📜 Contract Address
(Provide deployed contract addresses here upon mainnet/testnet launch)