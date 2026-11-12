// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract InitOrder {
    uint256[] public log;
    uint256 public a = mark(1);
    uint256 public b = mark(2);
    uint256 public c;

    constructor() {
        c = mark(3);
        a = 100;
    }

    function mark(uint256 x) internal returns (uint256) {
        log.push(x);
        return x;
    }

    function logged() external view returns (uint256[] memory) {
        return log;
    }
}
