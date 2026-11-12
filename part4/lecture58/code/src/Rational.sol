// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract Rational {
    function huge() external pure returns (uint256) {
        return (2**800 + 1) - 2**800;
    }

    function half() external pure returns (uint256) {
        uint x = 0.5 * 4;
        return x;
    }

    function divVar(uint a) external pure returns (uint256) {
        return a / 2;
    }
}
