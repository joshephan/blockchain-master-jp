// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Factory {
    Point public last;

    function make() external returns (address) {
        Child c = new Child();
        last = Point(1, 2);
        return address(c);
    }
}

contract Child {
    function hello() external pure returns (uint) {
        return 7;
    }
}

struct Point {
    uint x;
    uint y;
}
