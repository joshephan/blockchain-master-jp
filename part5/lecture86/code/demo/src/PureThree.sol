// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 確認用: 状態に触れない内部関数の三つの値
contract PureThree {
    function three(uint256 n) internal pure returns (uint256 a, uint256 b, uint256 c) {
        a = n;
        for (uint256 i = 0; i < n; i++) {
            b += i;
        }
        c = n * 2;
    }

    function takeAll(uint256 n) external pure returns (uint256 a, uint256 b, uint256 c) {
        (a, b, c) = three(n);
    }

    function takeOne(uint256 n) external pure returns (uint256 a) {
        (a, , ) = three(n);
    }
}
