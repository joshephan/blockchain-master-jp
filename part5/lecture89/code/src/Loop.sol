// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Loop {
    // 囲まない版
    function sumPlain(uint256 n) external pure returns (uint256 s) {
        for (uint256 i; i < n; ++i) {
            s += i;
        }
    }

    // インクリメントだけをuncheckedで囲んだ版
    function sumWrapped(uint256 n) external pure returns (uint256 s) {
        for (uint256 i; i < n;) {
            s += i;
            unchecked { ++i; }
        }
    }

    // インクリメントをi += 1と書いた版
    function sumPlusEq(uint256 n) external pure returns (uint256 s) {
        for (uint256 i; i < n; i += 1) {
            s += i;
        }
    }
}
