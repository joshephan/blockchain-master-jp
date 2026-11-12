// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Visits {
    address public owner;
    uint256 public visits;
    address public lastVisitor;
    uint256 constant MAX_VISITS = 1_000_000;

    function visit() external {
        uint256 next = bump(visits);
        require(next <= MAX_VISITS, "full");
        visits = next;
        lastVisitor = msg.sender;
    }

    function preview() external view returns (uint256 next, address who) {
        next = bump(visits);
        who = msg.sender;
    }

    function bump(uint256 v) internal pure returns (uint256) {
        return v + 1;
    }
}
