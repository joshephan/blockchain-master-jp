// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

// 返ってきた値を使わない三つの場所
contract Drop248 {
    struct Coin {
        uint256 value;
    }

    function take(uint256 v) internal pure returns (Coin memory) {
        return Coin(v);
    }

    function ignoreReturn() external pure {
        take(5);
    }

    function unusedLocal() external pure {
        Coin memory c = take(5);
    }

    function ignoreCall(address a) external {
        a.call("");
    }

    function copyCoin() external pure returns (uint256, uint256) {
        Coin memory a = take(5);
        Coin memory b = a;
        b.value = 7;
        return (a.value, b.value);
    }
}
