// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract InFunc {
    function f() external pure returns (uint256) {
        struct Pair { uint256 a; uint256 b; }
        return 1;
    }
}
