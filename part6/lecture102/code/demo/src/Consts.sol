// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Consts {
    bytes32 public constant ROLE = keccak256("ADMIN");
    string public constant NAME = "Market";
    uint256 public constant BIG = 2**800 / 2**799;
    uint256 public constant YEAR = 365 days;
}
