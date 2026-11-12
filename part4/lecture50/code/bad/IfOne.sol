// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract IfOne {
    function check() external pure returns (bool) {
        if (1) {
            return true;
        }
        return false;
    }
}
