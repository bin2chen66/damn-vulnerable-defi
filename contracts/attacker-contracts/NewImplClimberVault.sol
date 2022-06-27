// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../climber/ClimberVault.sol";

contract NewImplClimberVault is ClimberVault{
    function setNewSweeper(address newSweeper) external {
        _setSweeper(newSweeper);
    }
}
 