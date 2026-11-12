// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Twice {
    uint256 public c;
    uint256 public x;
    uint256 public i = 1;
    uint256[4] public a;

    function inc() internal returns (uint256) {
        c += 1;
        return c;
    }

    function sum() external {
        x = inc() + inc();
    }

    function tens() external {
        x = inc() * 10 + inc();
    }

    function slot() external {
        a[i] = i++;
    }
}

// 同じことを一行に一つずつ
contract TwiceSplit {
    uint256 public c;
    uint256 public x;
    uint256 public i = 1;
    uint256[4] public a;

    function inc() internal returns (uint256) {
        c += 1;
        return c;
    }

    function tens() external {
        uint256 first = inc();
        uint256 second = inc();
        x = first * 10 + second;
    }

    function slot() external {
        uint256 k = i;
        i = k + 1;
        a[k] = k;
    }
}
