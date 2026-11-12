// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Counter {
    uint256 public last;

    // 0からn-1まで足す、nは呼ぶ人が決める
    function run(uint256 n) external returns (uint256 s) {
        last = n;
        for (uint256 i = 0; i < n; i++) {
            s += i;
        }
    }

    // 合計がlimitを超えたらその場で終える
    function runCapped(uint256 n, uint256 limit) external returns (uint256 s) {
        last = n;
        for (uint256 i = 0; i < n; i++) {
            if (s > limit) {
                return s;
            }
            s += i;
        }
    }
}

contract LoopKinds {
    uint256 public spins;

    function whileCount(uint256 n) external pure returns (uint256 count) {
        while (count < n) {
            count++;
        }
    }

    function doWhileCount(uint256 n) external pure returns (uint256 count) {
        do {
            count++;
        } while (count < n);
    }

    // 偶数は飛ばし、stopで止まる
    function sumOdd(uint256 n, uint256 stop) external pure returns (uint256 s) {
        for (uint256 i = 0; i < n; i++) {
            if (i == stop) {
                break;
            }
            if (i % 2 == 0) {
                continue;
            }
            s += i;
        }
    }

    // 条件がいつまでも偽にならない
    function spin() external {
        spins += 1;
        uint256 i = 1;
        while (i != 0) {
            i += 2;
        }
    }
}
