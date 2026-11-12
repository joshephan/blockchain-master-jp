// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract BoolCast {
    function check(uint256 x) external pure returns (bool) {
        if (bool(x)) {
            return true;
        }
        return false;
    }
}
