// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";
import {MultiSigAdmin} from "./MultiSigAdmin.sol";

// 第178講: 管理者の席にマルチシグ(三人中二人)。管理者の鍵を失くしたり凍結したまま残っても、預けた人は引き出せる
contract KeysTest is Test {
    MockToken token;
    Market market;
    MultiSigAdmin ms;
    address a = address(0xA1);
    address b = address(0xB2);
    address c = address(0xC3);
    address bob = address(0xB0B);

    function setUp() public {
        address[] memory o = new address[](3);
        o[0] = a;
        o[1] = b;
        o[2] = c;
        ms = new MultiSigAdmin(o, 2);
        token = new MockToken();
        market = new Market(address(ms), Rate.wrap(5e16), Ratio.wrap(80));
        _run(a, b, abi.encodeCall(IMarket.addAsset, (IERC20(address(token)), Ratio.wrap(75))));
        token.transfer(bob, 100);
        vm.prank(bob);
        market.deposit(address(token), 100);
    }

    // 署名者二人が承認して実行
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

    function test_adminIsMultisig() public view {
        assertEq(market.admin(), address(ms));
        assertEq(ms.threshold(), 2);
        assertEq(ms.ownerCount(), 3);
        assertEq(market.assetCount(), 1);
    }

    function test_multisigFreezes() public {
        _run(b, c, abi.encodeCall(IMarket.setStatus, (IMarket.MarketStatus.Frozen)));
        assertEq(uint8(market.status()), 2);
    }

    function test_oneKeyCannotFreeze() public {
        vm.prank(a);
        uint256 id = ms.propose(address(market), abi.encodeCall(IMarket.setStatus, (IMarket.MarketStatus.Frozen)));
        vm.prank(a);
        ms.approve(id);
        vm.prank(a);
        vm.expectRevert(abi.encodeWithSelector(MultiSigAdmin.BelowThreshold.selector, id, 1));
        ms.execute(id);
        assertEq(uint8(market.status()), 0);
    }

    function test_signerAloneNotAdmin() public {
        vm.prank(a);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotAdmin.selector, a));
        market.setStatus(IMarket.MarketStatus.Frozen);
    }

    function test_frozenStillWithdraws() public {
        _run(a, c, abi.encodeCall(IMarket.setStatus, (IMarket.MarketStatus.Frozen)));
        vm.prank(bob);
        market.withdrawAll(address(token));
        assertEq(token.balanceOf(bob), 100);
        (Amount d,,,) = market.positions(address(token), bob);
        assertEq(Amount.unwrap(d), 0);
    }

    // 管理者の鍵が一つだけの市場が凍結した後、その鍵を失くした場合。解除する人はいなくても引き出しはできる
    function test_lostKeyFrozenStillWithdraws() public {
        address lost = address(0x1057);
        Market m = new Market(lost, Rate.wrap(5e16), Ratio.wrap(80));
        vm.prank(lost);
        m.addAsset(IERC20(address(token)), Ratio.wrap(75));
        token.transfer(bob, 50);
        vm.prank(bob);
        m.deposit(address(token), 50);
        vm.prank(lost);
        m.setStatus(IMarket.MarketStatus.Frozen);
        uint256 before = token.balanceOf(bob);
        vm.prank(bob);
        m.withdraw(address(token), 50);
        assertEq(token.balanceOf(bob), before + 50);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotActive.selector, IMarket.MarketStatus.Frozen));
        m.deposit(address(token), 1);
    }
}
