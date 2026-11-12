// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";

// 第144講: 他人の分が入った市場で、預けた量より多く引き出す呼び出し。引き出しを止める三つのチェック(InsufficientDeposit、Amountの-のオーバーフローチェック、assert)のうち
// 先頭のInsufficientDepositで巻き戻り、二人の分とトークン残高がそのままかを確認
contract GuardsTest is Test {
    MockToken token;
    Market market;
    address one = address(0x1001);
    address two = address(0x2002);

    function setUp() public {
        token = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        token.transfer(one, 900);
        token.transfer(two, 1);
        vm.prank(one);
        market.deposit(address(token), 900);
        vm.prank(two);
        market.deposit(address(token), 1);
    }

    function test_withdrawOverDepositKeepsOthersFunds() public {
        vm.prank(two);
        vm.expectRevert(abi.encodeWithSelector(IMarket.InsufficientDeposit.selector, uint256(1), uint256(901)));
        market.withdraw(address(token), 901);
        (Amount d1,,,) = market.positions(address(token), one);
        (Amount d2,,,) = market.positions(address(token), two);
        assertEq(Amount.unwrap(d1), 900);
        assertEq(Amount.unwrap(d2), 1);
        assertEq(token.balanceOf(address(market)), 901);
        assertEq(token.balanceOf(two), 0);
    }
}
