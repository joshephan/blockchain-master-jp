// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 値を一つ保存するコントラクト
contract Store {
    uint256 public v = 7; // 最初の値

    // 読み取り
    function get() external view returns (uint256) { return v; }

    function set(uint256 x) external {
        v   =   x;
    }
}
