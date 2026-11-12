// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract StringIndex {
    function f() external pure returns (bytes1) {
        string memory s = unicode"あい";
        return s[0];
    }
}
