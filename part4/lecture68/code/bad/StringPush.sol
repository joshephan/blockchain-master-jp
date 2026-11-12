// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract StringPush {
    string public s;
    function f() external {
        s.push(0x41);
    }
}
