// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract ThisAddr {
    function me() external view returns (address) {
        address a = this;
        return a;
    }
}
