// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 親の版1: fなし
contract P {
    uint256 public n;
}
contract C is P {
    function f() public pure returns (uint256) { return 2; }
}
