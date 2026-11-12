// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract X {
    /// @return a 一つ目
    /// @return b 二つ目
    function f() external pure returns (uint256 a) { a = 1; }
}
