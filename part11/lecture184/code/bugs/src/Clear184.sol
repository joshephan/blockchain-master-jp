// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// ストレージの欄とtransientの欄を一つのコントラクトで両方消す
contract Clear184 {
    uint256 public s;
    uint256 transient t;

    function run() external returns (uint256 sAfter, uint256 tAfter) {
        s = 1;
        t = 1;
        delete t;
        delete s;
        return (s, t);
    }
}

// ストレージの欄だけを消す(transientなし)
contract ClearOnly184 {
    uint256 public s;

    function run() external returns (uint256 sAfter) {
        s = 1;
        delete s;
        return s;
    }
}
