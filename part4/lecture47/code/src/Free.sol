// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

function double(uint256 x) pure returns (uint256) {
    return x * 2;
}

contract UsesFree {
    function twice(uint256 x) external pure returns (uint256) {
        return double(x);
    }
}
