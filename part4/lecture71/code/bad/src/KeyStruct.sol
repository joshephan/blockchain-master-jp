// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract KeyStruct {
    struct Pair {
        address a;
        address b;
    }

    mapping(Pair => uint256) public m;
}
