// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Order {
    uint256[] public log;

    function g() internal returns (uint256) {
        log.push(1);
        return 10;
    }

    function h() internal returns (uint256) {
        log.push(2);
        return 20;
    }

    function f(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function args() external returns (uint256[] memory) {
        f(g(), h());
        return log;
    }

    function plus() external returns (uint256[] memory) {
        uint256 r = g() + h();
        r;
        return log;
    }
}
