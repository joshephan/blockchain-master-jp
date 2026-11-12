// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Owned {
    address public owner;
    uint256 public fee;

    error NotOwner(address caller);

    constructor() {
        owner = msg.sender;
    }

    function setFee(uint256 newFee) external {
        if (msg.sender != owner) revert NotOwner(msg.sender);
        fee = newFee;
    }
}
