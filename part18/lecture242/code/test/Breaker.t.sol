// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, stdError} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MultiSigAdmin} from "./MultiSigAdmin.sol";
import {FeeSwitchToken} from "./FeeSwitchToken.sol";

// 第241講: 上場したトークンがあとから手数料をオンにすると、トークン残高が帳簿より少なくなる。停止スイッチ(setStatus)が防ぐものと防げないもの
contract BreakerTest is Test {
    FeeSwitchToken token;
    Market market;
    MultiSigAdmin ms;
    address a = address(0xA1);
    address b = address(0xB2);
    address c = address(0xC3);
    address bob = address(0xB0B);
    address carol = address(0xCA201);
    address dave = address(0xDA7E);
    uint256 pauseId; // 事前に承認しておいた預け入れ停止の提案

    function setUp() public {
        address[] memory o = new address[](3);
        o[0] = a;
        o[1] = b;
        o[2] = c;
        ms = new MultiSigAdmin(o, 2);
        token = new FeeSwitchToken();
        market = new Market(address(ms), Rate.wrap(5e16), Ratio.wrap(80));
        _run(a, b, abi.encodeCall(IMarket.addAsset, (IERC20(address(token)), Ratio.wrap(75))));
        // 預け入れ停止の提案を先に作り、二人が承認だけしておく。実行は署名者の誰か一人
        vm.prank(a);
        pauseId = ms.propose(address(market), abi.encodeCall(IMarket.setStatus, (IMarket.MarketStatus.DepositPaused)));
        vm.prank(a);
        ms.approve(pauseId);
        vm.prank(b);
        ms.approve(pauseId);
        token.transfer(bob, 100);
        token.transfer(carol, 100);
        token.transfer(dave, 100);
        vm.prank(bob);
        market.deposit(address(token), 100);
    }

    function _run(address x, address y, bytes memory data) internal {
        vm.prank(x);
        uint256 id = ms.propose(address(market), data);
        vm.prank(x);
        ms.approve(id);
        vm.prank(y);
        ms.approve(id);
        vm.prank(x);
        ms.execute(id);
    }

    function _ledger() internal view returns (uint256) {
        return Amount.unwrap(market.totalDeposits(address(token)));
    }

    // 手数料0のときはトークン残高 = 帳簿
    function test_coverHoldsBeforeFee() public view {
        assertEq(token.balanceOf(address(market)), 100);
        assertEq(_ledger(), 100);
    }

    // 手数料1%をオンにしたあと預け入れ100: 帳簿は200、トークン残高は199
    function test_feeSwitchBreaksCover() public {
        token.setFee(100);
        vm.prank(carol);
        market.deposit(address(token), 100);
        assertEq(_ledger(), 200);
        assertEq(token.balanceOf(address(market)), 199);
        (Amount d,,,) = market.positions(address(token), carol);
        assertEq(Amount.unwrap(d), 100);
    }

    // 事前に承認しておいた提案は署名者一人が実行。新しく作った提案は一人ではできない
    function test_preApprovedPauseOneSigner() public {
        vm.prank(c);
        ms.execute(pauseId);
        assertEq(uint8(market.status()), 1);
        vm.prank(c);
        uint256 id = ms.propose(address(market), abi.encodeCall(IMarket.setStatus, (IMarket.MarketStatus.Active)));
        vm.prank(c);
        ms.approve(id);
        vm.prank(c);
        vm.expectRevert(abi.encodeWithSelector(MultiSigAdmin.BelowThreshold.selector, id, 1));
        ms.execute(id);
    }

    // 事前に承認した提案は一度だけ実行される
    function test_preApprovedOnlyOnce() public {
        vm.prank(c);
        ms.execute(pauseId);
        vm.prank(a);
        vm.expectRevert(abi.encodeWithSelector(MultiSigAdmin.AlreadyExecuted.selector, pauseId));
        ms.execute(pauseId);
    }

    // 止めたあと: 新しい預け入れはふさがり、出金はそのまま
    function test_pauseStopsDepositsOnly() public {
        token.setFee(100);
        vm.prank(carol);
        market.deposit(address(token), 100);
        vm.prank(c);
        ms.execute(pauseId);
        vm.prank(dave);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotActive.selector, IMarket.MarketStatus.DepositPaused));
        market.deposit(address(token), 100);
        vm.prank(bob);
        market.withdrawAll(address(token));
        assertEq(token.balanceOf(bob), 99); // 出るときも1%引く
        assertEq(token.balanceOf(address(market)), 99);
        assertEq(_ledger(), 100);
    }

    // 止めてもすでにできた穴は残る: 最後の人は自分の持ち分を全部は引き出せない
    function test_lastWithdrawerShort() public {
        token.setFee(100);
        vm.prank(carol);
        market.deposit(address(token), 100);
        vm.prank(c);
        ms.execute(pauseId);
        vm.prank(bob);
        market.withdrawAll(address(token));
        vm.prank(carol);
        vm.expectRevert(stdError.arithmeticError); // トークン残高99から100を引こうとしてPanic 0x11
        market.withdrawAll(address(token));
        vm.prank(carol);
        market.withdraw(address(token), 99);
        assertEq(token.balanceOf(address(market)), 0);
        assertEq(_ledger(), 1);
    }

    // Frozenも出金を止められない(第178講の決定)
    function test_frozenCannotStopWithdraw() public {
        _run(a, b, abi.encodeCall(IMarket.setStatus, (IMarket.MarketStatus.Frozen)));
        vm.prank(bob);
        market.withdraw(address(token), 40);
        assertEq(token.balanceOf(bob), 40);
    }
}
