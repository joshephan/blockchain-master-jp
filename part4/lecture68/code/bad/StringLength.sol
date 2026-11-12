// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract StringLength {
    function f() external pure returns (uint256) {
        string memory s = unicode"あい";
        return s.length;
    }
}
