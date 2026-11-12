// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio} from "../src/Market.sol";
import {MockToken} from "../src/Tokens.sol";

// 第89講末の版に同じテストを二つ
contract WithdrawTest is Test {
    Market market;
    MockToken tk;
    address alice = address(0xA11CE);

    function setUp() public {
        market = new Market();
        tk = new MockToken(1000);
        market.addAsset(IERC20(address(tk)), Ratio.wrap(75));
        tk.transfer(alice, 100);
        vm.prank(alice);
        tk.approve(address(market), 100);
        vm.prank(alice);
        market.deposit(address(tk), 100);
    }

    // 理由なし: 巻き戻りさえすれば合格
    function test_anyRevert() public {
        vm.prank(alice);
        vm.expectRevert();
        market.withdraw(address(tk), 150);
    }

    // 理由まで: InsufficientDeposit(100, 150)でなければ不合格
    function test_reason() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSignature("InsufficientDeposit(uint256,uint256)", 100, 150));
        market.withdraw(address(tk), 150);
    }
}
