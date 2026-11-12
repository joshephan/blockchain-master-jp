// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 親の版2: 同じ名前のfを足す
contract P {
    uint256 public n;
    function f() public pure returns (uint256) { return 1; }
}
contract C is P {
    function f() public pure returns (uint256) { return 2; }
}
