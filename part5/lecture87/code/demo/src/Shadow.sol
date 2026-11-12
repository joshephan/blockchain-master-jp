// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Shadow {
    function f() external pure returns (uint256) {
        uint256 x = 1;
        {
            uint256 x = 2;
            x += 10;
        }
        return x;
    }
}
