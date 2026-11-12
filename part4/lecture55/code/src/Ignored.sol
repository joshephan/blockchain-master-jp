// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Ignored {
    uint256 public reached;

    constructor() payable {}

    function sendIgnored(address payable to) external {
        to.send(1 ether);
        reached += 1;
    }

    function callIgnored(address to) external {
        to.call{value: 1 ether}("");
        reached += 1;
    }
}
