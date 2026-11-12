// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Holder {
    uint256[] public arr;
    uint256 public total;

    function fill(uint256 n) external {
        for (uint256 i = 0; i < n; i++) {
            arr.push(i + 1);
        }
        total = 7;
    }

    function readCopy(uint256 i) external view returns (uint256) {
        uint256[] memory c = arr;
        return c[i];
    }

    function readRef(uint256 i) external view returns (uint256) {
        uint256[] storage c = arr;
        return c[i];
    }

    function readOnce() external view returns (uint256) {
        return total;
    }

    function readThrice() external view returns (uint256) {
        return total + total + total;
    }
}
