// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract X {
    error Closed();

    function f() external pure {
        revert Closed;
    }
}
