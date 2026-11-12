// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";

// 第158講: Marketの帳簿はトークン残高ではなくtotalDeposits・positions。depositを通さずに送ったトークンは
// 帳簿に載らず、誰も取り出せない。金庫の標準(ERC-4626)のdepositとMarketのdepositはセレクターが違う
contract DonationTest is Test {
    Market market;
    MockToken token;
    address alice = address(0xA11CE);

    function setUp() public {
        token = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        token.transfer(alice, 200);
    }

    function test_directTransferStaysAfterWithdrawAll() public {
        vm.prank(alice);
        market.deposit(address(token), 100);
        token.transfer(address(market), 50);
        assertEq(token.balanceOf(address(market)), 150);
        assertEq(Amount.unwrap(market.totalDeposits(address(token))), 100);
        vm.prank(alice);
        market.withdrawAll(address(token));
        assertEq(token.balanceOf(alice), 200);
        assertEq(token.balanceOf(address(market)), 50);
        assertEq(Amount.unwrap(market.totalDeposits(address(token))), 0);
    }

    function test_depositSelectorDiffersFrom4626() public pure {
        assertEq(IMarket.deposit.selector, bytes4(keccak256("deposit(address,uint256)")));
        assertEq(bytes4(keccak256("deposit(uint256,address)")), bytes4(0x6e553f65));
        assertTrue(IMarket.deposit.selector != bytes4(0x6e553f65));
    }
}
