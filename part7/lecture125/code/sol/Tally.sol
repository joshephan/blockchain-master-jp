// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Tally {
    uint256 public count;
    address public owner;

    event Bumped(uint256 n);
    error NotOwner();

    constructor() {
        owner = msg.sender;
    }

    function bump() external {
        count += 1;
        emit Bumped(count);
    }

    function setOwner(address a) external {
        if (msg.sender != owner) revert NotOwner();
        owner = a;
    }
}
