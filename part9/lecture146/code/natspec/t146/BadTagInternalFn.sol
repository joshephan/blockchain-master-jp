// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract X {
    /// @foo 存在しないタグ
    function _f(uint256 x) internal pure returns (uint256) { return x; }
    function g() external pure returns (uint256) { return _f(1); }
}
