// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

interface IVault {
    error Short(uint256 have, uint256 want);
    function take(uint256 want) external;
}

contract X {
    function f(IVault v) external {
        try v.take(5) {
        } catch Short(uint256 h, uint256 w) {
        }
    }
}
