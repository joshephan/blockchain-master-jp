// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Base {
    address public owner = msg.sender;
    modifier onlyOwner() virtual { require(msg.sender == owner, "not owner"); _; }
}
contract Child is Base {
    modifier onlyOwner() override { _; }
}
