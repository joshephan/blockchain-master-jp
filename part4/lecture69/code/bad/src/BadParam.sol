// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract BadParam {
    function f(bytes calldata data) external pure {
        data[0] = 0x01;
    }
}
