// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Runs139 {
    uint256 public v;

    function big() external {
        v = 0x1000000000000000000000000000000000000000000000000000000000000000;
    }

    function f1() external { v = 1; }
    function f2() external { v = 2; }
    function f3() external { v = 3; }
    function f4() external { v = 4; }
    function f5() external { v = 5; }
    function f6() external { v = 6; }
    function f7() external { v = 7; }
}
