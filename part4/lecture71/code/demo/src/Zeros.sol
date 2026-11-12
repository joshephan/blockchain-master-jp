// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Zeros {
    struct Info {
        uint256 amount;
        bool active;
        address owner;
    }

    mapping(address => uint256) public amounts;
    mapping(address => bool) public flags;
    mapping(address => address) public owners;
    mapping(address => Info) public infos;
}
