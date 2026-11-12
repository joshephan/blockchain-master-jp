// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {stdError} from "forge-std/StdError.sol";
import {Market, MarketBase, IERC20, Ratio, Rate, InsufficientDeposit, NotAdmin} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";

// 第108講: Marketの巻き戻りデータの形。先頭4バイトがセレクター、後ろに引数が32バイトずつ
contract ErrorDataTest is Test {
    MockToken token;
    Market market;
    address bob = address(0xB0B);

    function setUp() public {
        token = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        market.deposit(address(token), 100);
    }

    // 関数を呼ぶcalldataと同じ形: 4 + 32 + 32 = 68バイト
    function test_insufficientDepositBytes() public {
        (bool ok, bytes memory data) = address(market).call(abi.encodeCall(IMarket.withdraw, (address(token), 150)));
        assertFalse(ok);
        assertEq(data.length, 68);
        assertEq(bytes4(data), IMarket.InsufficientDeposit.selector);
        assertEq(data, abi.encodeWithSelector(InsufficientDeposit.selector, uint256(100), uint256(150)));
    }

    // catchでは名前を選んで受け取れない。bytesで受け取って先頭4バイトを比較
    function test_catchBytesCompare() public {
        vm.prank(bob);
        try market.setStatus(MarketBase.MarketStatus.Frozen) {
            fail();
        } catch (bytes memory data) {
            assertEq(bytes4(data), IMarket.NotAdmin.selector);
            assertEq(data, abi.encodeWithSelector(NotAdmin.selector, bob));
        }
    }

    // トークンが出した巻き戻りは、Marketのエラー一覧になくてもそのまま上がってくる
    function test_tokenRevertBubbles() public {
        vm.expectRevert(stdError.arithmeticError); // MockTokenの残高900から1000を引く、Panic(0x11)
        market.deposit(address(token), 1000);
        token.setBroken(true);
        vm.expectRevert(bytes("token paused")); // MockTokenのrequire文字列、Error(string)
        market.deposit(address(token), 1);
    }
}
