// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {ReentrancyGuard} from "@oz/utils/ReentrancyGuard.sol";

// ロック一つを二つの関数が共有する。ロックの欄は継承した_status一つ
contract Lock250 is ReentrancyGuard {
    uint256 public count;

    function a() external nonReentrant {
        count += 1;
        this.b(); // 同じコントラクトの別のロックされた関数を外から呼ぶ
    }

    function b() external nonReentrant {
        count += 10;
    }
}
