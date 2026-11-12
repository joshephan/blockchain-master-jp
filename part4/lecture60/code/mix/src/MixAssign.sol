// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

type Amount18 is uint256;
type Amount6 is uint256;

contract MixAssign {
    function f(Amount6 amount6) external pure returns (Amount18) {
        Amount18 a = amount6;
        return a;
    }
}
