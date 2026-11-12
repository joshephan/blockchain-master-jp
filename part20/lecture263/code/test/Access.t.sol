// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {Market} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {StdToken} from "./helpers/StdToken.sol";
import {TwapFeed} from "./helpers/TwapFeed.sol";
import {MultiSigAdmin} from "./helpers/MultiSigAdmin.sol";

// 権限の要件A-01~A-05。テスト名の頭の番号がdesign/requirements.mdの要件番号
// デプロイの形(設計文書3節): 設定キー = タイムロック(最小待機2日、提案・実行 = マルチシグ、タイムロックの管理者 = タイムロック自身)
// 停止キー = マルチシグ(三つのうち二つ)を直接。デプロイアカウントに残るロールなし
contract AccessTest is Test {
    StdToken col;
    StdToken usd;
    TwapFeed colFeed;
    TwapFeed usdFeed;
    Market market;
    TimelockController timelock;
    MultiSigAdmin council;
    address a = address(0xA);
    address b = address(0xB);
    address c = address(0xC);
    address bob = address(0xB0B);
    address alice = address(0xA11CE);
    address stranger = address(0xBAD);
    uint256 salt;

    function setUp() public {
        address[] memory owners = new address[](3);
        owners[0] = a;
        owners[1] = b;
        owners[2] = c;
        council = new MultiSigAdmin(owners, 2);
        address[] memory roles = new address[](1);
        roles[0] = address(council);
        timelock = new TimelockController(2 days, roles, roles, address(0));
        market = new Market(address(timelock), address(council), 0);
        col = new StdToken("Collateral", "COL", 18);
        usd = new StdToken("Dollar", "USD", 6);
        colFeed = new TwapFeed(1e18);
        usdFeed = new TwapFeed(1e18);
        vm.warp(vm.getBlockTimestamp() + 1 hours);
        _viaTimelock(abi.encodeCall(IMarket.listAsset, (address(col), colFeed, 75, type(uint256).max)));
        _viaTimelock(abi.encodeCall(IMarket.listAsset, (address(usd), usdFeed, 80, type(uint256).max)));
        usd.mint(bob, 1000e6);
        col.mint(alice, 1000e18);
        vm.startPrank(bob);
        usd.approve(address(market), type(uint256).max);
        market.deposit(address(usd), 1000e6);
        vm.stopPrank();
        vm.startPrank(alice);
        col.approve(address(market), type(uint256).max);
        usd.approve(address(market), type(uint256).max);
        market.deposit(address(col), 1000e18);
        market.setCollateral(address(col), true);
        market.borrow(address(usd), 500e6);
        vm.stopPrank();
    }

    // マルチシグが提案・承認二つ・実行で呼ぶ
    function _council(address target, bytes memory data) internal {
        vm.prank(a);
        uint256 id = council.propose(target, data);
        vm.prank(a);
        council.approve(id);
        vm.prank(b);
        council.approve(id);
        vm.prank(a);
        council.execute(id);
    }

    // タイムロックに上げ(schedule)、2日後に実行(execute)。どちらもマルチシグが呼ぶ
    function _viaTimelock(bytes memory data) internal {
        salt++;
        _council(
            address(timelock),
            abi.encodeCall(timelock.schedule, (address(market), 0, data, bytes32(0), bytes32(salt), 2 days))
        );
        vm.warp(vm.getBlockTimestamp() + 2 days);
        _council(
            address(timelock), abi.encodeCall(timelock.execute, (address(market), 0, data, bytes32(0), bytes32(salt)))
        );
    }

    // 設定キー・停止キーで呼べる関数を全部呼んでも、金庫のトークンと預けた量はそのまま
    function test_A01_noKeyMovesDeposits() public {
        uint256 vaultUsd = usd.balanceOf(address(market));
        uint256 vaultCol = col.balanceOf(address(market));
        StdToken t = new StdToken("New", "NEW", 18);
        TwapFeed f = new TwapFeed(1e18);
        vm.warp(vm.getBlockTimestamp() + 30 minutes);
        _viaTimelock(abi.encodeCall(IMarket.listAsset, (address(t), f, 50, 1000e18)));
        _viaTimelock(abi.encodeCall(IMarket.setSupplyCap, (address(usd), 2000e6)));
        _council(address(market), abi.encodeCall(IMarket.pause, (address(usd), 3)));
        _viaTimelock(abi.encodeCall(IMarket.unpause, (address(usd), 3)));
        _viaTimelock(abi.encodeCall(IMarket.setGuardian, (address(council))));
        assertEq(usd.balanceOf(address(market)), vaultUsd);
        assertEq(col.balanceOf(address(market)), vaultCol);
        assertEq(market.depositOf(address(usd), bob), 1000e6);
        assertEq(market.depositOf(address(col), alice), 1000e18);
    }

    // マルチシグが直接呼ぶとNotAdmin。タイムロックに上げたあと2日前は実行できず、そのあいだbobは引き出せる
    function test_A02_configWaitsForTimelock() public {
        StdToken t = new StdToken("New", "NEW", 18);
        TwapFeed f = new TwapFeed(1e18);
        vm.warp(vm.getBlockTimestamp() + 30 minutes);
        bytes memory data = abi.encodeCall(IMarket.listAsset, (address(t), f, 80, type(uint256).max));
        vm.prank(address(council));
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotAdmin.selector, address(council)));
        market.listAsset(address(t), f, 80, type(uint256).max);
        _council(
            address(timelock),
            abi.encodeCall(timelock.schedule, (address(market), 0, data, bytes32(0), bytes32("x"), 2 days))
        );
        bytes32 id = timelock.hashOperation(address(market), 0, data, bytes32(0), bytes32("x"));
        assertEq(timelock.getTimestamp(id), vm.getBlockTimestamp() + 2 days);
        vm.prank(a);
        uint256 early = council.propose(
            address(timelock), abi.encodeCall(timelock.execute, (address(market), 0, data, bytes32(0), bytes32("x")))
        );
        vm.prank(a);
        council.approve(early);
        vm.prank(b);
        council.approve(early);
        vm.prank(a);
        vm.expectRevert(abi.encodeWithSelector(MultiSigAdmin.CallFailed.selector, early));
        council.execute(early);
        vm.prank(alice);
        market.repay(address(usd), type(uint256).max);
        vm.prank(bob);
        market.withdrawAll(address(usd)); // 待機中に抜け出す
        assertEq(usd.balanceOf(bob), 1000e6);
        vm.warp(vm.getBlockTimestamp() + 2 days);
        vm.prank(a);
        council.execute(early);
        assertEq(market.assetCount(), 3);
        // デプロイアカウントにはタイムロックの管理者ロールがなく、タイムロック自身が持つ
        assertFalse(timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), address(this)));
        assertTrue(timelock.hasRole(timelock.DEFAULT_ADMIN_ROLE(), address(timelock)));
        assertEq(timelock.getMinDelay(), 2 days);
    }

    // 停止キーはすぐ止める。事前に承認しておいた提案は署名者一人が実行。停止キーで他の設定はできない
    function test_A03_guardianOnlyPauses() public {
        vm.prank(a);
        uint256 pre = council.propose(address(market), abi.encodeCall(IMarket.pause, (address(usd), 3)));
        vm.prank(a);
        council.approve(pre);
        vm.prank(b);
        council.approve(pre);
        vm.prank(c);
        council.execute(pre); // 署名者c一人で
        (,,, uint8 bits,,) = market.assetConfig(address(usd));
        assertEq(bits, 3);
        vm.prank(stranger);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotGuardian.selector, stranger));
        market.pause(address(col), 1);
        vm.startPrank(address(council));
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotAdmin.selector, address(council)));
        market.unpause(address(usd), 3);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotAdmin.selector, address(council)));
        market.setSupplyCap(address(usd), 0);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotAdmin.selector, address(council)));
        market.setGuardian(stranger);
        vm.stopPrank();
        vm.prank(bob);
        market.withdraw(address(usd), 100e6); // 止めても引き出せる
        vm.prank(alice);
        market.repay(address(usd), 100e6); // 止めても返せる
    }

    // 再開はタイムロックの2日後。停止キーを変えると古い停止キーはNotGuardian
    function test_A04_unpauseNeedsTimelock() public {
        _council(address(market), abi.encodeCall(IMarket.pause, (address(usd), 1)));
        uint256 t0 = vm.getBlockTimestamp();
        _viaTimelock(abi.encodeCall(IMarket.unpause, (address(usd), 1)));
        assertEq(vm.getBlockTimestamp() - t0, 2 days);
        (,,, uint8 bits,,) = market.assetConfig(address(usd));
        assertEq(bits, 0);
        address newGuardian = address(0x6A2D);
        _viaTimelock(abi.encodeCall(IMarket.setGuardian, (newGuardian)));
        assertEq(market.guardian(), newGuardian);
        vm.prank(address(council));
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotGuardian.selector, address(council)));
        market.pause(address(usd), 1);
        vm.prank(newGuardian);
        market.pause(address(usd), 1);
    }

    // コードを変える道なし: ランタイムにDELEGATECALL・CALLCODE・SELFDESTRUCTが0個、アップグレード関数なし、EIP-1967の実装スロットは0
    function test_A05_noUpgradePath() public {
        bytes memory code = address(market).code;
        uint256 meta = uint256(uint8(code[code.length - 2])) << 8 | uint256(uint8(code[code.length - 1]));
        uint256 end = code.length - meta - 2;
        uint256 found;
        for (uint256 i = 0; i < end; i++) {
            uint8 op = uint8(code[i]);
            if (op == 0xf4 || op == 0xf2 || op == 0xff) found++;
            if (op >= 0x60 && op <= 0x7f) i += op - 0x5f;
        }
        assertEq(found, 0);
        (bool ok,) = address(market).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(1), ""));
        assertFalse(ok);
        (ok,) = address(market).call(abi.encodeWithSignature("proxiableUUID()"));
        assertFalse(ok);
        bytes32 implSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        assertEq(vm.load(address(market), implSlot), bytes32(0));
    }
}
