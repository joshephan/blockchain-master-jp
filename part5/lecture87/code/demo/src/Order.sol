// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Order {
    function bump() external returns (uint256) {
        count = next(count);
        return count;
    }

    function next(uint256 v) internal pure returns (uint256) {
        return v + 1;
    }

    uint256 public count;
}
