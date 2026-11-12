// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

type Amount is uint256;

contract MapMem {
    struct Account {
        Amount total;
        mapping(address => Amount) perAsset;
    }

    Account acc;

    function f() external view returns (uint256) {
        Account memory a = acc;
        return Amount.unwrap(a.total);
    }
}
