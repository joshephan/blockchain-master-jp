// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract OneWord {
    bytes32 public id;

    function set(bytes32 v) external {
        id = v;
    }
}

contract FourTags {
    bytes4 public a;
    bytes4 public b;
    bytes4 public c;
    bytes4 public d;

    function set() external {
        a = 0x11111111;
        b = 0x22222222;
        c = 0x33333333;
        d = 0x44444444;
    }
}

contract TextAndNumber {
    bytes32 public s = "abc";
    uint256 public n = 0x616263;
}
