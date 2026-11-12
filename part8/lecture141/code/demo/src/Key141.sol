// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract Key141 {
    mapping(address => uint256) public a; // スロット0
    mapping(string => uint256) public s;  // スロット1
    function set() external { a[address(0x1234)] = 7; s["hi"] = 8; }
}
