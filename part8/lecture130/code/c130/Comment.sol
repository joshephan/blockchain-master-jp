// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Store {
    // 最初の値7
    uint256 public v = 7;

    function get() external view returns (uint256) {
        return v;
    }

    function set(uint256 x) external {
        v = x;
    }
}
