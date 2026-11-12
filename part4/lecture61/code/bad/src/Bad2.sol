// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Bad2 {
    function triple(uint256 x) internal pure returns (uint256) {
        return x * 3;
    }

    function pickTriple() public view returns (bytes4) {
        return this.triple.selector;
    }
}
