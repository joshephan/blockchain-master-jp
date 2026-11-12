// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract FixedAssign {
    ufixed128x18 x;

    function set() external {
        x = 1.5;
    }
}
