// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract X {
    /// @return b 名前が違う
    function f() external pure returns (uint256 a) { a = 1; }
}
