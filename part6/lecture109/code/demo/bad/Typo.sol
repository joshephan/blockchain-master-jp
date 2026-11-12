// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Typo {
    error Short(uint256 have, uint256 want);

    function f(uint256 a) external pure {
        if (a > 3) revert Shrot(3, a);
    }
}
