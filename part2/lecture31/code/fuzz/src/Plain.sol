// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Plain {
    function open(uint256 x) public pure returns (bool) {
        if (x == 20261018) {
            return false;
        }
        return true;
    }
}
