// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Swap {
    uint256 public x = 1;
    uint256 public y = 2;

    function swap() external {
        (x, y) = (y, x);
    }

    function literals() external pure returns (uint8 small, int8 neg) {
        (small, neg) = (1, -1);
    }
}

// 確認用: ストレージ配列の入れ替え
contract SwapArr {
    uint256[] public p;
    uint256[] public q;

    constructor() {
        p.push(1);
        q.push(2);
        q.push(3);
    }

    function swap() external {
        (p, q) = (q, p);
    }

    function both() external view returns (uint256[] memory, uint256[] memory) {
        return (p, q);
    }
}
