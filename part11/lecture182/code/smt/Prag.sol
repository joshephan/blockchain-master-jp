// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
pragma experimental SMTChecker;

contract Prag {
    function bad(uint256 x) external pure returns (uint256) {
        assert(x != 7);
        return x;
    }
}
