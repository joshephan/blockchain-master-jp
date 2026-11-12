// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

error NotOwner(address caller);

contract Ownable {
    address public owner = msg.sender;

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner(msg.sender);
        _;
    }
}
