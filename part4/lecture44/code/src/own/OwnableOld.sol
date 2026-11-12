// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Ownable {
    address public owner = msg.sender;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }
}
