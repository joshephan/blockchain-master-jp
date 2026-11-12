// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Plain {

    function mulDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b / 1e18;
    }

    function f(uint256 a, uint256 b) external pure returns (uint256) {
        return mulDiv(a, b);
    }
}
