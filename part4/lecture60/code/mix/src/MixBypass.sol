// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

type Amount18 is uint256; // 小数点以下18桁のトークン金額
type Amount6 is uint256;  // 小数点以下6桁のトークン金額
type Price is uint256;    // 倍率6

contract MixBypass {
    function total(Amount18 amount18, Amount6 amount6) external pure returns (Amount18) {
        return Amount18.wrap(Amount18.unwrap(amount18) + Amount6.unwrap(amount6));
    }

    function anything() external pure returns (Price) {
        return Price.wrap(123);
    }
}
