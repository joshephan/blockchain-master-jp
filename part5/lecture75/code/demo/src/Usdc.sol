// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

type Amount6 is uint256; // 小数点以下6桁のトークン金額 (第60講)

contract UsdcVault {
    uint256 public usdcBalance; // 6桁のトークン金額

    function addHundred() external {
        usdcBalance += 100 ether;
    }

    function wrapped() external pure returns (Amount6) {
        return Amount6.wrap(100 ether);
    }
}
