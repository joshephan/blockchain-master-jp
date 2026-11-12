// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract MapStruct {
    struct Account {
        uint256 total;
        mapping(address => uint256) byAsset;
    }

    Account public acct; // スロット0: total、スロット1: byAsset

    function fill(address asset, uint256 v) external {
        acct.total = v;
        acct.byAsset[asset] = v;
    }

    function wipe() external {
        delete acct;
    }

    function byAsset(address asset) external view returns (uint256) {
        return acct.byAsset[asset];
    }
}
