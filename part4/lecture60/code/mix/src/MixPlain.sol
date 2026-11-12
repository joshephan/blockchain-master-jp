// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract MixPlain {
    /// @param amount18 小数点以下18桁のトークン金額
    /// @param amount6  小数点以下6桁のトークン金額
    function total(uint256 amount18, uint256 amount6)
        external pure returns (uint256)
    {
        return amount18 + amount6;
    }
}
