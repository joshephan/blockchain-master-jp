// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract FakeToken {
    function transfer(address, uint) external pure returns (bool) {
        return true;
    }

    function balanceOf(address) external pure returns (uint) {
        return 1000000;
    }
}
