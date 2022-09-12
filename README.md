# Damn Vulnerable DeFi Writeup

🚧 WIP

Solutions to [Damn Vulnerable DeFi](https://www.damnvulnerabledefi.xyz/) CTF challenges ⛳️

## Contents

1.  [Unstoppable](#1-unstoppable)
2.  [Naive receiver](#2-naive-receiver)
3.  [Truster](#3-truster)
4.  [Side entrance](#4-side-entrance)
5.  [The rewarder](#5-the-rewarder)
6.  [Selfie](#6-selfie)
7.  [Compromised](#7-compromised)
8.  [Puppet](#8-puppet)
9.  [Puppet v2](#9-puppet-v2)
10. [Free rider](#10-free-rider)
11. [Backdoor](#11-backdoor)
12. [Climber](#12-climber)
13. [Safe miners](#13-safe-miners)

## 1 - Unstoppable

The goal of the first challenge is to perform a DOS (Denial of Service) attack to the contract.

There is a suspicious line in the `flashLoan` function:

```solidity
uint256 balanceBefore = damnValuableToken.balanceOf(address(this));
assert(poolBalance == balanceBefore);
```

If we can manage to alter the `poolBalance` or the `balanceBefore`, we will achieve the goal.

We can easily modify the `balanceBefore` by sending some token to the pool.

[Test](./test/unstoppable/unstoppable.challenge.ts)

## 2 - Naive receiver

In this challenge we have to drain all the funds from a contract made to call flash loans.

The contract expects to be called from the pool, which is fine, but the vulnerability lies on the fact that anyone can call the flash loan function of the pool.

In order to empty the contract in one transaction, we can create an attacker contract that calls the flash loan multiple times.

[Test](./test/naive-receiver/naive-receiver.challenge.ts)

## 3 - Truster

Here we have to get all the tokens from the pool, and our starter balance is 0.

The `flashLoan` from the pool lets us call any function in any contract. So, what we can do is:

- Call the `flashLoan` with a function to `approve` the pool's tokens to be used by the attacker
- Call the `transferFrom` function of the token, to transfer them to the attacker address

If we want to make it in one transaction, we can create a contract that calls the `flashLoan` with the `approve`, but instead of the attacker address, we set the created contract address. Then we transfer the tokens to the attacker in the same tx.

[Test](./test/truster/truster.challenge.ts)

## 4 - Side entrance

For this challenge we have to take all the ETH from the pool contract.

It has no function to receive ETH, other than the `deposit`, which is also the attack vector.

We can create an attacker contract that asks for a flash loan, and then deposit the borrowed ETH. The pool will believe that our balance is 1000 ETH, and that the flash loan was properly paid. Then we can withdraw it.

[Test](./test/side-entrance/side-entrance.challenge.ts)

## 5 - The rewarder

Here we have to claim rewards from a pool we shouldn't be able to.

Rewards are distributed when someone calls `distributeRewards()`, and depending on the amount of tokens deposited.

So, we can do all of this in one transaction:

0. Wait five days (minimum period between rewards)
1. Get a flash loan with a huge amount of tokens
2. Deposit the tokens in the pool
3. Distribute the rewards
4. Withdraw the tokens from the pool
5. Pay back the flash loan

[Test](./test/the-rewarder/the-rewarder.challenge.ts)

## 6 - Selfie

The goal of this challenge is to drain all the tokens from the pool.

The pool has a `drainAllFunds(address)` function that can only be executed by a _governance_ address, and this is what we will be exploiting:

1. Request a flash loan and get all the tokens from the pool
2. Take a `snapshot` of the tokens -> Here lies one vulnerability. Anyone can take a snapshot at any time
3. Propose to execute an action to transfer all tokens to the attacker (the proposal will be admited since we have a lot of tokens in the snapshot)
4. Return the flash loan tokens to the pool
5. Wait two days (the grace period for the proposal)
6. Execute the action to drain all funds

[Test](./test/selfie/selfie.challenge.ts)

## 7 - Compromised

[Test](./test/compromised/compromised.challenge.ts)

## 8 - Puppet

[Test](./test/puppet/puppet.challenge.ts)

## 9 - Puppet v2

[Test](./test/puppet-v2/puppet-v2.challenge.ts)

## 10 - Free rider

[Test](./test/free-rider/free-rider.challenge.ts)

## 11 - Backdoor

[Test](./test/backdoor/backdoor.challenge.ts)

## 12 - Climber

[Test](./test/climber/climber.challenge.ts)

## 13 - Safe miners

[Test](./test/safe-miners/safe-miners.challenge.ts)
