// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {StdToken} from "./StdToken.sol";
import {IMarket} from "../../src/IMarket.sol";

// テスト用のトークン。動く瞬間にMarketの帳簿を読んで書いておく(読むだけ、Marketの関数を呼び直さない)
contract HookToken is StdToken {
    IMarket public market;
    address public watched;
    uint256 public seenDeposits;
    uint256 public seenDebt;

    constructor() StdToken("Hook", "HOOK", 18) {}

    function watch(IMarket m, address user) external {
        market = m;
        watched = user;
    }

    function _move(address from, address to, uint256 amount) internal override {
        if (address(market) != address(0) && (from == address(market) || to == address(market))) {
            seenDeposits = market.totalDeposits(address(this));
            seenDebt = market.debtOf(address(this), watched);
        }
        super._move(from, to, amount);
    }
}
