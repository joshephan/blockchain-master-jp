// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract SelfRef {
    struct Node {
        uint256 value;
        Node child;
    }
}
