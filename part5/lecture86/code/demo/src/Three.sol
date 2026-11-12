// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 三つの値を返す関数
contract Source {
    event Made(uint256 n);

    function three() external returns (uint256 a, uint256 b, uint256 c) {
        a = 7;
        emit Made(a);
        b = 8;
        emit Made(b);
        c = 9;
        emit Made(c);
    }
}

contract Reader {
    Source public src;

    constructor(Source s) {
        src = s;
    }

    function takeAll() external returns (uint256 sum) {
        (uint256 a, uint256 b, uint256 c) = src.three();
        sum = a + b + c;
    }

    function takeOne() external returns (uint256 a) {
        (a, , ) = src.three();
    }
}
