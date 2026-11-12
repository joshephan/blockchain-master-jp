// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Nested {
    function f(uint8 a) external pure returns (uint8) {
        unchecked {
            unchecked { return a + 1; }
        }
    }
}
