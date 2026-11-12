// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";

// 第144講のデモ: 他人の分が入った市場で、預けた量より多く引き出す呼び出し
contract DrainTest is Test {
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

    function test_withdrawMoreThanDeposit() public {
        vm.prank(two);
        (bool ok, bytes memory ret) = address(market).call(abi.encodeCall(IMarket.withdraw, (address(token), 901)));
        console.log("ok", ok);
        console.logBytes(ret);
        console.log("two token balance", token.balanceOf(two));
        console.log("market token balance", token.balanceOf(address(market)));
        (Amount d,,,) = market.positions(address(token), two);
        console.log("two deposited", Amount.unwrap(d));
        assertFalse(ok);
        assertEq(ret, abi.encodeWithSelector(IMarket.InsufficientDeposit.selector, uint256(1), uint256(901)));
    }
}
