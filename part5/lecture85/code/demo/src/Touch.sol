// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第74講そのまま
contract Touch {
    uint256[3] public arr;
    uint256 public i;

    function touch() external { arr[i++] += 1; }
}
