// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Lit1 {
    function f() public pure returns (uint256) {
        uint256[3] memory a = [1, 2, 3];
        return a[0];
    }
}
