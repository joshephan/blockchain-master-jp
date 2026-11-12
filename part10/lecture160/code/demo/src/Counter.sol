// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 最初の版。一回に1ずつ数える
contract CounterV1 {
    uint256 public count;

    function inc() external {
        count += 1;
    }

    function version() external pure returns (uint256) {
        return 1;
    }

    // このコードが動くときのaddress(this)とmsg.sender
    function whoami() external view returns (address self, address sender) {
        return (address(this), msg.sender);
    }
}

// 二つ目の版。一回に10ずつ数える。状態変数の配置は最初の版と同じ
contract CounterV2 {
    uint256 public count;

    function inc() external {
        count += 10;
    }

    function version() external pure returns (uint256) {
        return 2;
    }

    function whoami() external view returns (address self, address sender) {
        return (address(this), msg.sender);
    }
}
