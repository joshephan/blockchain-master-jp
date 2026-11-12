// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 実装のアドレスを普通の状態変数(スロット0)に置いたプロキシ
contract NaiveProxy {
    address public implementation; // スロット0
    address public owner; // スロット1

    constructor(address impl) {
        implementation = impl;
        owner = msg.sender;
    }

    function upgradeTo(address impl) external {
        require(msg.sender == owner, "not owner");
        implementation = impl;
    }

    fallback() external {
        address impl = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let ok := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch ok
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
