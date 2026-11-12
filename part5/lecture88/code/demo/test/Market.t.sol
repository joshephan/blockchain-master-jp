// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Amount} from "../src/Market.sol";
import {BorrowDraft} from "../src/BorrowDraft.sol";
import {Token} from "../src/Token.sol";

contract MarketTest is Test {
    Market m;
    Token t;

    function setUp() public {
        m = new Market();
        t = new Token();
        m.addAsset(IERC20(address(t)), Ratio.wrap(75));
        t.approve(address(m), 100);
        m.deposit(address(t), 100);
    }

    function test_withdrawTooMuch() public {
        m.withdraw(address(t), 150);
    }

    function test_withdrawAll() public {
        m.withdraw(address(t), 100);
        console.log("totalDeposits", Amount.unwrap(m.totalDeposits(address(t))));
    }
}

contract BorrowDraftTest is Test {
    BorrowDraft d;
    Token t;

    function setUp() public {
        d = new BorrowDraft();
        t = new Token();
        d.addAsset(IERC20(address(t)), Ratio.wrap(75));
        t.approve(address(d), 100);
        d.deposit(address(t), 100);
    }

    function test_borrowPastRatio() public {
        d.borrow(address(t), 1_000_000);
        (Amount dep, Amount bor, , ) = d.positions(address(t), address(this));
        console.log("deposited", Amount.unwrap(dep));
        console.log("borrowed ", Amount.unwrap(bor));
    }
}
