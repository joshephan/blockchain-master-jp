// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Box {
    uint256 public value;

    error Nope(uint256 code);

    function store(uint256 v) external {
        value = v;
    }

    function fail() external pure {
        revert Nope(7);
    }
}
