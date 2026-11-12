// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract SelOv {
    function f(uint256 a) public pure returns (uint256) {
        return a;
    }

    function f(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }

    function g() external view returns (bytes4) {
        return this.f.selector;
    }
}
