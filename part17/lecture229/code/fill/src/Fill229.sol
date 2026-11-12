// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// 新しいストレージスロットをn個使うコントラクト(状態の増加の測定用)
contract Fill229 {
    mapping(uint256 => uint256) public slot;
    uint256 public next;

    function fill(uint256 n) external {
        uint256 s = next;
        for (uint256 i; i < n; ++i) {
            slot[s + i] = 1;
        }
        next = s + n;
    }
}
