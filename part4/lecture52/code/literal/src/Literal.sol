// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract Literal {
    function f() external pure returns (uint256) {
        return 1 << 256;
    }
}
