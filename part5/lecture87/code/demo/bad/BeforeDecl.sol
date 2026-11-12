// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract BeforeDecl {
    function f() external pure returns (uint256) {
        uint256 a = b + 1;
        uint256 b = 2;
        return a;
    }
}
