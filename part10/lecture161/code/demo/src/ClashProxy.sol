// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// プロキシ自身に公開関数があるプロキシ。その関数のセレクターが実装の関数burn(uint256)と同じ(0x42966c68)
contract ClashProxy {
    bytes32 internal constant IMPL_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    event Intercepted(address caller);

    constructor(address impl) {
        assembly {
            sstore(IMPL_SLOT, impl)
        }
    }

    // 名前も引数もburnと違う。セレクターだけが同じ
    function collate_propagate_storage(bytes16) external {
        emit Intercepted(msg.sender);
    }

    fallback() external {
        assembly {
            let impl := sload(IMPL_SLOT)
            calldatacopy(0, 0, calldatasize())
            let ok := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch ok
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
