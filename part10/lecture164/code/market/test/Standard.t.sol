// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {MockToken} from "../src/MockToken.sol";
import {StdToken} from "./StdToken.sol";

// 第154講: ERC-20が定める関数六つ(オプションの関数三つを除く)。MarketのIERC20はこのうち三つ
interface IERC20Six {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

// 第154講: MarketはIERC20の三つの関数だけを呼ぶ。標準どおりに承認を要求するトークンとかみ合うか、
// テスト用のMockTokenが標準とどこで違うかを確認
contract StandardTest is Test {
    Market market;
    StdToken std;
    address alice = address(0xA11CE);

    function setUp() public {
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        std = new StdToken("Std Token", "STD", 18, 1000);
        std.transfer(alice, 1000);
        market.addAsset(IERC20(address(std)), Ratio.wrap(75));
    }

    function test_stdTokenRoundTrip() public {
        vm.startPrank(alice);
        std.approve(address(market), 100);
        market.deposit(address(std), 100);
        market.withdraw(address(std), 30);
        vm.stopPrank();
        (Amount d,,,) = market.positions(address(std), alice);
        assertEq(Amount.unwrap(d), 70);
        assertEq(std.balanceOf(address(market)), 70);
        assertEq(std.balanceOf(alice), 930);
        assertEq(std.allowance(alice, address(market)), 0);
    }

    function test_noApproveBubbles() public {
        vm.prank(alice);
        vm.expectRevert(bytes("insufficient allowance"));
        market.deposit(address(std), 100);
    }

    function test_mockTokenMovesWithoutApproval() public {
        MockToken mock = new MockToken();
        mock.transfer(alice, 500);
        vm.prank(address(0xB0B));
        mock.transferFrom(alice, address(0xB0B), 500);
        assertEq(mock.balanceOf(address(0xB0B)), 500);
    }

    function test_interfaceIds() public pure {
        assertEq(type(IERC20).interfaceId, bytes4(0xfa1d6c57));
        assertEq(type(IERC20Six).interfaceId, bytes4(0x36372b07));
    }
}
