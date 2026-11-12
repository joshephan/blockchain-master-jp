// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Market, Position, Amount} from "./Market.sol";

// デモ用: 担保比率を見ない借り入れの草案 (プロジェクトのコードには入れない)
contract BorrowDraft is Market {
    function borrow(address asset, uint256 amount) external {
        Position storage p = positions[asset][msg.sender];
        p.borrowed = Amount.wrap(Amount.unwrap(p.borrowed) + amount);
        totalBorrows[asset] = Amount.wrap(Amount.unwrap(totalBorrows[asset]) + amount);
    }
}
