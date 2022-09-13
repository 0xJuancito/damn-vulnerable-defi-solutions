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

The goal here is to drain all the ETH from the exchange.

The exchange only has two methods, one to buy a token, and the other to sell it. The price is given by an oracle.

The oracle is properly initialized and only some trusted sources can update price with the `postPrice` method.

The key to solve this challenge is in the misterious message from the web service:

```
4d 48 68 6a 4e 6a 63 34 5a 57 59 78 59 57 45 30 4e 54 5a 6b 59 54 59 31 59 7a 5a 6d 59 7a 55 34 4e 6a 46 6b 4e 44 51 34 4f 54 4a 6a 5a 47 5a 68 59 7a 42 6a 4e 6d 4d 34 59 7a 49 31 4e 6a 42 69 5a 6a 42 6a 4f 57 5a 69 59 32 52 68 5a 54 4a 6d 4e 44 63 7a 4e 57 45 35

4d 48 67 79 4d 44 67 79 4e 44 4a 6a 4e 44 42 68 59 32 52 6d 59 54 6c 6c 5a 44 67 34 4f 57 55 32 4f 44 56 6a 4d 6a 4d 31 4e 44 64 68 59 32 4a 6c 5a 44 6c 69 5a 57 5a 6a 4e 6a 41 7a 4e 7a 46 6c 4f 54 67 33 4e 57 5a 69 59 32 51 33 4d 7a 59 7a 4e 44 42 69 59 6a 51 34
```

It's some code in hex. Let's convert it to Ascii code:

```
MHhjNjc4ZWYxYWE0NTZkYTY1YzZmYzU4NjFkNDQ4OTJjZGZhYzBjNmM4YzI1NjBiZjBjOWZiY2RhZTJmNDczNWE5
MHgyMDgyNDJjNDBhY2RmYTllZDg4OWU2ODVjMjM1NDdhY2JlZDliZWZjNjAzNzFlOTg3NWZiY2Q3MzYzNDBiYjQ4
```

Information in the web is sometimes encoded in Base64. Let's try decoding it:

```
0xc678ef1aa456da65c6fc5861d44892cdfac0c6c8c2560bf0c9fbcdae2f4735a9
0x208242c40acdfa9ed889e685c23547acbed9befc60371e9875fbcd736340bb48
```

This looks like private keys! And they are. We can check the addresses they correspond to, and they are in fact the addresses from two of the trusted sources.

With these keys, we can manipulate the price of the token to buy low and sell high, extracting all the ETH from the contract.

[Test](./test/compromised/compromised.challenge.ts)

## 8 - Puppet

The goal of this challenge is to drain all of the tokens from a pool.

There's a `borrow` function in the pool that lets people borrow tokens for twice their price in ETH.

The vulnerability lies on the fact that it is taking the price from a Uniswap pool with very low liquidity.

So, we can lower the token price of the Uniswap pool by swapping some ETH to tokens.

Then, when the price is low enough, we can borrow all the tokens from the pool for a very low price.

[Test](./test/puppet/puppet.challenge.ts)

## 9 - Puppet v2

This challenge has the same issues as the previous one. The price from the pool relies on a single oracle that can be attacked to change the price.

The attack is the same as in the previous challenge, but instead of interacting with Uniswap v1, in this case its v2:

```typescript
await this.token.connect(attacker).approve(this.uniswapRouter.address, ATTACKER_INITIAL_TOKEN_BALANCE);
const deadline = (await ethers.provider.getBlock("latest")).timestamp * 2;

await this.uniswapRouter
  .connect(attacker)
  .swapExactTokensForETH(
    ATTACKER_INITIAL_TOKEN_BALANCE,
    0,
    [this.token.address, this.weth.address],
    attacker.address,
    deadline,
    { gasLimit: 1e6 },
  );

const tokens = await this.lendingPool.calculateDepositOfWETHRequired(POOL_INITIAL_TOKEN_BALANCE);
await this.weth.connect(attacker).deposit({ value: tokens });
await this.weth.connect(attacker).approve(this.lendingPool.address, tokens);

await this.lendingPool.connect(attacker).borrow(POOL_INITIAL_TOKEN_BALANCE);
```

[Test](./test/puppet-v2/puppet-v2.challenge.ts)

## 10 - Free rider

[Test](./test/free-rider/free-rider.challenge.ts)

## 11 - Backdoor

[Test](./test/backdoor/backdoor.challenge.ts)

## 12 - Climber

[Test](./test/climber/climber.challenge.ts)

## 13 - Safe miners

[Test](./test/safe-miners/safe-miners.challenge.ts)
