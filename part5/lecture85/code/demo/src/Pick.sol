// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Pick {
    uint256[] public log;

    function g() internal returns (bool) {
        log.push(1);
        return true;
    }

    function h() internal returns (bool) {
        log.push(2);
        return true;
    }

    function andLeft(bool left) external returns (uint256[] memory) {
        if (left && g()) {}
        return log;
    }

    function orLeft(bool left) external returns (uint256[] memory) {
        if (left || g()) {}
        return log;
    }

    function pick(bool c) external returns (uint256[] memory) {
        c ? g() : h();
        return log;
    }
}
