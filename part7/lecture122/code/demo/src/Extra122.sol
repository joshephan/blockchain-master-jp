// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第122講の補足: 呼ぶ前にコードがあるかを手で確認する版
contract RawChecked {
    function viaAssemblyChecked(address t) external view returns (uint256 ok, uint256 v) {
        assembly {
            if iszero(extcodesize(t)) { revert(0, 0) }
            let p := mload(0x40)
            mstore(p, shl(224, 0x3fa4f245)) // value()
            ok := staticcall(gas(), t, p, 4, p, 0x20)
            v := mload(p)
        }
    }

    function viaAssemblyUnchecked(address t) external view returns (uint256 ok, uint256 v) {
        assembly {
            let p := mload(0x40)
            mstore(p, shl(224, 0x3fa4f245)) // value()
            ok := staticcall(gas(), t, p, 4, p, 0x20)
            v := mload(p)
        }
    }
}
