// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract BadMem {
    function f(bytes memory data) public pure returns (bytes memory) {
        return data[4:];
    }
}
