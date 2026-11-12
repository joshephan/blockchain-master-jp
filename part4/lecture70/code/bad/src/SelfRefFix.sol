// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract TreeArray {
    struct Node {
        uint256 value;
        Node[] children;
    }
    Node root;
}

contract TreeIndex {
    struct Node {
        uint256 value;
        uint256 parent; // nodesの中の番号
    }
    Node[] nodes;
}
