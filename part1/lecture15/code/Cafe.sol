// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPoints {
    function add(address user, uint256 amount) external;
}

contract Cafe {
    IPoints public points;
    uint256 public orders;
    uint256 public pointFails;

    constructor(IPoints p) { points = p; }

    function orderA() external {
        orders += 1;
        points.add(msg.sender, 45);
    }

    function orderB() external {
        orders += 1;
        (bool ok, ) = address(points).call(
            abi.encodeCall(IPoints.add, (msg.sender, 45))
        );
        if (!ok) pointFails += 1;
    }
}
