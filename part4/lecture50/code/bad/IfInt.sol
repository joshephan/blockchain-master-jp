// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract IfInt {
    uint256 public count;

    function check() external view returns (bool) {
        if (count) {
            return true;
        }
        return false;
    }
}
