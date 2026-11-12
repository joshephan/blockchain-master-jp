// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Typo {
    /// @custom:smtchecker abstract-function-nondett
    function g(uint256 a) internal pure returns (uint256) {
        return a + 1;
    }

    function f(uint256 a) external pure returns (uint256) {
        return g(a);
    }
}
