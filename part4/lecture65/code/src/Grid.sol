// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Grid {
    uint256[2][3] public a;

    function put(uint256 i, uint256 j, uint256 v) external {
        a[i][j] = v;
    }

    function at(uint256 i, uint256 j) external view returns (uint256) {
        return a[i][j];
    }

    function outer() external view returns (uint256) {
        return a.length;
    }

    function inner() external view returns (uint256) {
        return a[0].length;
    }
}
