// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

type Amount is uint256;

contract MapStore {
    struct Account {
        Amount total;
        mapping(address => Amount) perAsset;
    }

    Account acc;

    function f() external view returns (uint256) {
        Account storage a = acc;
        return Amount.unwrap(a.total);
    }
}
