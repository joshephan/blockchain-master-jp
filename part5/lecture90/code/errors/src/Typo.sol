// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

error TooSmall(uint256 got, uint256 min);

contract Typo {
    function revErr(uint256 x) external pure {
        if (x < 10) revert TooSmal(x, 10);
    }
}
