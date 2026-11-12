// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract CdWrite {
    function f(uint256[] calldata xs) external pure returns (uint256) {
        xs[0] = 1;
        return xs[0];
    }
}
