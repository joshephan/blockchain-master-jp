// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

error Short(uint256 want);

contract X {
    error Short(uint256 have, uint256 want);

    function f() external pure {
        revert Short(1, 2);
    }
}
