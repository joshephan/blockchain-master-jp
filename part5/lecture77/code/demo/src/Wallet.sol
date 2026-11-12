// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Market} from "./Market.sol";

// ユーザーの代わりにMarketを呼んでくれるウォレットコントラクト (デモ用)
contract Wallet {
    function depositTo(Market market, address asset, uint256 amount) external {
        market.deposit(asset, amount);
    }
}
