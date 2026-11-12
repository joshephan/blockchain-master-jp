// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract DepositOv {
    function deposit(address asset, uint256 amount) external pure returns (uint256) {
        return amount;
    }

    function deposit(IERC20 asset, uint256 amount) external pure returns (uint256) {
        return amount + 1;
    }
}
