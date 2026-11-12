// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract DivUnchecked {
    function div(uint256 a, uint256 b) external pure returns (uint256) {
        unchecked { return a / b; }
    }
}
