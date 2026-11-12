// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract Small {
    // uint8で4分の3を求める
    function threeQuartersMulFirst(uint8 x) external pure returns (uint8) {
        return x * 3 / 4;
    }

    function threeQuartersDivFirst(uint8 x) external pure returns (uint8) {
        return x / 4 * 3;
    }
}
