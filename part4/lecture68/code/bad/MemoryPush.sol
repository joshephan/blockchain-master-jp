// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract MemoryPush {
    function f() external pure returns (uint256) {
        bytes memory b = hex"0102";
        b.push(0x03);
        return b.length;
    }
}
