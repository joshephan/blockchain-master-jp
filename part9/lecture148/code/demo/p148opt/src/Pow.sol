// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract P {
    function f(uint256 y, uint256 z) public pure returns (uint256 x) {
        x = 2**3 + 5;
        x = 2*y + 3*z;
        if (x < 10) x += 1;
        if (x < 10)
            x += 1;
    }
}
