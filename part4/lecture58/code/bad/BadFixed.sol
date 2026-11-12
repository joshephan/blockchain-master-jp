// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract BadFixed {
    function f() external pure {
        ufixed8x1 x = 5 / 2;
        x;
    }
}
