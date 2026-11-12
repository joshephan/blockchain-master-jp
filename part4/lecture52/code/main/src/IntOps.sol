// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract IntOps {
    function div(uint256 a, uint256 b) external pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) external pure returns (uint256) {
        return a % b;
    }

    function sdiv(int256 a, int256 b) external pure returns (int256) {
        return a / b;
    }

    function smod(int256 a, int256 b) external pure returns (int256) {
        return a % b;
    }

    function div8(int8 a, int8 b) external pure returns (int8) {
        return a / b;
    }

    function neg8(int8 a) external pure returns (int8) {
        return -a;
    }

    function pow(uint256 a, uint256 b) external pure returns (uint256) {
        return a ** b;
    }
}
