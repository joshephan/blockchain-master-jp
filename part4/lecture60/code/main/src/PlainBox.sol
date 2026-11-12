// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract PlainBox {
    uint256 public price;

    function set(uint256 p) external {
        price = p;
    }

    function get() external view returns (uint256) {
        return price;
    }
}
