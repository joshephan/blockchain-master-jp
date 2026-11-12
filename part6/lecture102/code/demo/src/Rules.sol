// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Twice {
    uint256 public immutable v;

    constructor() {
        v = 1;
        v = 2;
    }
}

contract ReadEarly {
    uint256 public immutable v;
    uint256 public seen;

    constructor() {
        seen = v;
        v = 7;
    }
}

contract Never {
    uint256 public immutable v;
}
