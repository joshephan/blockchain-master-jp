// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract ForVar {
    function f() external pure returns (uint256) {
        uint256 sum;
        for (uint256 i = 0; i < 3; i++) {
            sum += i;
        }
        return i;
    }
}
