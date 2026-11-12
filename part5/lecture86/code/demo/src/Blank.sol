// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 空けた場所に記録を残す関数を入れた版
contract Blank {
    uint256[] public log;

    function mark(uint256 n) internal returns (uint256) {
        log.push(n);
        return n;
    }

    function run() external returns (uint256 a) {
        (a, , ) = (mark(1), mark(2), mark(3));
    }

    function logged() external view returns (uint256[] memory) {
        return log;
    }
}
