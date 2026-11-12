// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

type Amount18 is uint256;

contract Amount18Call {
    function f(uint256 x) external pure returns (Amount18) {
        return Amount18(x);
    }
}
