// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";

// 第44章の確認用: Marketがすでに防いでいるかを攻撃者のトークンで試す。Marketのsrcは変えない。

// transferの途中でMarket.withdrawをもう一度呼ぶトークン(再入の試み)
contract ReentrantToken {
    mapping(address => uint256) public balanceOf;
    Market public market;
    bool armed;
    uint256 public reenterTries;

    function mint(address to, uint256 a) external {
        balanceOf[to] += a;
    }

    function setMarket(Market m) external {
        market = m;
    }

    function transferFrom(address from, address to, uint256 a) external returns (bool) {
        balanceOf[from] -= a;
        balanceOf[to] += a;
        return true;
    }

    function transfer(address to, uint256 a) external returns (bool) {
        balanceOf[msg.sender] -= a;
        balanceOf[to] += a;
        // 受け取るふりをしてMarket.withdrawをもう一度呼ぶ
        if (armed) {
            armed = false;
            reenterTries++;
            // to(=今回のwithdrawのmsg.sender)になりすまして、もう一度引き出しを試みる
            market.withdraw(address(this), a);
        }
        return true;
    }

    function arm() external {
        armed = true;
    }
}

contract Reentrancy44Test is Test {
    Market market;

    function setUp() public {
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
    }

    // withdrawが帳簿を先に減らし(_debit)、トークンを後で送るので(CEI)、
    // transferの途中で再入しても、すでに減った帳簿なので二回引き出せない
    function test_withdrawCeiBlocksReentry() public {
        ReentrantToken token = new ReentrantToken();
        token.setMarket(market);
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        token.mint(address(token), 1000); // Marketが送る流動性

        // トークン自身が100を預け入れ(トークンがmsg.sender)
        token.mint(address(token), 100);
        vm.prank(address(token));
        market.deposit(address(token), 100);

        (Amount before,,,) = market.positions(address(token), address(token));
        assertEq(Amount.unwrap(before), 100);

        token.arm();
        vm.prank(address(token));
        // 100を引き出す。transferの途中で再入のwithdraw(100)を呼ぶが、帳簿がすでに0なので巻き戻す
        vm.expectRevert(); // 再入のwithdrawが_debitでオーバーフローにより巻き戻り、全体が巻き戻る
        market.withdraw(address(token), 100);

        // 巻き戻ったので帳簿もそのまま100。二回引き出せなかった
        (Amount after_,,,) = market.positions(address(token), address(token));
        assertEq(Amount.unwrap(after_), 100);
    }
}
