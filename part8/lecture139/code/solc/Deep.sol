// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第121講のDeepからアセンブリブロックを除いた版: ローカル変数二十二個
contract Deep {
    function deep(uint256 x) public pure returns (uint256 r) {
        uint256 b0 = x + 1;
        uint256 b1 = x + 2;
        uint256 b2 = x + 3;
        uint256 b3 = x + 4;
        uint256 b4 = x + 5;
        uint256 b5 = x + 6;
        uint256 b6 = x + 7;
        uint256 b7 = x + 8;
        uint256 b8 = x + 9;
        uint256 b9 = x + 10;
        uint256 b10 = x + 11;
        uint256 b11 = x + 12;
        uint256 b12 = x + 13;
        uint256 b13 = x + 14;
        uint256 b14 = x + 15;
        uint256 b15 = x + 16;
        uint256 b16 = x + 17;
        uint256 b17 = x + 18;
        uint256 b18 = x + 19;
        uint256 b19 = x + 20;
        uint256 b20 = x + 21;
        uint256 b21 = x + 22;
        for (uint256 i = 0; i < x; i++) {
            b0 = b0 + b1;
            b1 = b1 + b2;
            b2 = b2 + b3;
            b3 = b3 + b4;
            b4 = b4 + b5;
            b5 = b5 + b6;
            b6 = b6 + b7;
            b7 = b7 + b8;
            b8 = b8 + b9;
            b9 = b9 + b10;
            b10 = b10 + b11;
            b11 = b11 + b12;
            b12 = b12 + b13;
            b13 = b13 + b14;
            b14 = b14 + b15;
            b15 = b15 + b16;
            b16 = b16 + b17;
            b17 = b17 + b18;
            b18 = b18 + b19;
            b19 = b19 + b20;
            b20 = b20 + b21;
            b21 = b21 + b0;
        }
        r = b0 + b1 + b2 + b3 + b4 + b5 + b6 + b7 + b8 + b9 + b10 + b11 + b12 + b13 + b14 + b15 + b16 + b17 + b18 + b19 + b20 + b21;
    }
}
