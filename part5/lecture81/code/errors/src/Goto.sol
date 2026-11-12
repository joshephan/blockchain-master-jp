// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Goto {
    function f() external pure returns (uint256 r) {
        goto done;
        r = 1;
    }
}
