// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 代入の左側の欄を決める式と右側の値、どちらが先に実行されるか
contract Side {
    uint256[] public log;
    uint256[3] public slots;

    function left() internal returns (uint256) {
        log.push(1); // 左
        return 0;
    }

    function right() internal returns (uint256) {
        log.push(2); // 右
        return 42;
    }

    function run() external {
        slots[left()] = right();
    }

    function logged() external view returns (uint256[] memory) {
        return log;
    }
}
