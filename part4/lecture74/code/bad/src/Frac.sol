// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Frac {
    function f() external pure returns (uint256) {
        return 1.5 + (true ? 1.5 : 2.5);
    }
}
