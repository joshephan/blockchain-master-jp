// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract AddHundred {
    function addHundred(uint8 a) external pure returns (uint256) {
        uint256 b = a + 100;
        return b;
    }

    function addHundredWide(uint8 a) external pure returns (uint256) {
        uint256 b = uint256(a) + 100;
        return b;
    }
}
