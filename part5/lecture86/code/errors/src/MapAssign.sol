// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract MapAssign {
    struct Account {
        uint256 total;
        mapping(address => uint256) byAsset;
    }

    Account public acct;
    Account public backup;

    function copy() external {
        backup = acct;
    }
}
