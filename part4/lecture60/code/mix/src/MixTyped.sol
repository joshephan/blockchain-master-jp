// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

type Amount18 is uint256; // 小数点以下18桁のトークン金額
type Amount6 is uint256;  // 小数点以下6桁のトークン金額

contract MixTyped {
    function total(Amount18 amount18, Amount6 amount6)
        external pure returns (Amount18)
    {
        return amount18 + amount6;
    }
}
