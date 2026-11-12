// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Sender {
    uint256 public reached;

    constructor() payable {}

    function viaTransfer(address payable to) external {
        to.transfer(1 ether);
        reached += 1;
    }

    function viaSend(address payable to) external returns (bool ok) {
        ok = to.send(1 ether);
        reached += 1;
    }

    function viaCall(address to) external returns (bool ok) {
        (ok, ) = to.call{value: 1 ether}("");
        reached += 1;
    }
}
