// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第97講の確認用: vをinternalにした版
contract StoreI {
    uint256 internal v = 5;

    function readOnce() external view returns (uint256) { return v; }
}
