// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract ExtByName {
    function withdraw(address asset, uint256 amount) external pure returns (uint256) {
        return amount;
    }

    function withdrawAll(address asset) external pure returns (uint256) {
        return withdraw(asset, 100);
    }
}
