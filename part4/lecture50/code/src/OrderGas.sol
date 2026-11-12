// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract OrderGas {
    uint256 public maxAmount = 1000;

    function cheapFirst(uint256 amount) external view returns (bool) {
        return amount == 0 || amount > maxAmount;
    }

    function storageFirst(uint256 amount) external view returns (bool) {
        return amount > maxAmount || amount == 0;
    }
}
