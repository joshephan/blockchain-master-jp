// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第121講の確認: 第40講のsplitSignatureのvの行からbyte(0, ...)を除いた版
contract Sig121 {
    function vByte(bytes memory sig) public pure returns (uint8 v) {
        assembly { v := byte(0, mload(add(sig, 96))) }
    }

    function vRaw(bytes memory sig) public pure returns (uint8 v, uint256 raw) {
        assembly {
            v := mload(add(sig, 96))
            raw := v
        }
    }
}
