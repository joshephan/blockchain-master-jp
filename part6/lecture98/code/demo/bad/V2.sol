// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract V2 {
    event Seen(uint256 v);
    function f() external view { emit Seen(1); }
}
