// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract X {
    error Short(uint256 have, uint256 want);

    function f() external {
        emit Short(1, 2);
    }
}
