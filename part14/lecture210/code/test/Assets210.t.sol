// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Base57} from "./Base57.sol";
import {Message} from "../src/Msg57.sol";
import {ToyOutbox} from "../src/Outbox57.sol";
import {ToyEndpoint} from "../src/Endpoint57.sol";
import {AttesterVerifier} from "../src/Verifiers57.sol";
import {TestToken, LockBox, Minter, WrappedToken, PoolBridge, PeerApp} from "../src/Assets57.sol";

// 第210講: ロックアップ・ミント(ロックして発行、バーンして解放)と流動性プール。メッセージの道は第208講のoutbox・endpointのまま、検証は確認者一人
contract AssetsTest is Base57 {
    ToyOutbox outboxA;
    ToyOutbox outboxB;
    AttesterVerifier verA;
    AttesterVerifier verB;
    ToyEndpoint endA;
    ToyEndpoint endB;
    TestToken tka;
    LockBox box;
    Minter minter;
    WrappedToken wtka;
    address attester = makeAddr("attester");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        vm.chainId(A);
        outboxA = new ToyOutbox();
        vm.chainId(B);
        outboxB = new ToyOutbox();
        verB = new AttesterVerifier(attester);
        endB = new ToyEndpoint(verB, _one(A), _oneAddr(address(outboxA)));
        vm.chainId(A);
        verA = new AttesterVerifier(attester);
        endA = new ToyEndpoint(verA, _one(B), _oneAddr(address(outboxB)));

        vm.chainId(A);
        tka = new TestToken("Token A", "TKA");
        box = new LockBox(outboxA, address(endA), tka);
        vm.chainId(B);
        minter = new Minter(outboxB, address(endB), 1000, address(this));
        wtka = minter.wrapped();
        box.setPeer(B, address(minter));
        minter.setPeer(A, address(box));
        tka.transfer(alice, 300);
        vm.recordLogs();
    }

    // 確認者が確認して誰でも入れる
    function _relay(ToyEndpoint end, AttesterVerifier ver, uint256 dst) internal returns (bytes32 id) {
        Message memory m;
        (id, m) = _lastMessage();
        vm.chainId(dst);
        vm.prank(attester);
        ver.attest(id);
        end.deliver(m, "");
    }

    function _lock(uint256 amount) internal {
        vm.chainId(A);
        vm.startPrank(alice);
        tka.approve(address(box), amount);
        box.lock(amount, bob);
        vm.stopPrank();
    }

    function test_lockThenMint() public {
        _lock(100);
        assertEq(box.locked(), 100);
        assertEq(tka.balanceOf(address(box)), 100);
        assertEq(wtka.totalSupply(), 0);
        _relay(endB, verB, B);
        assertEq(wtka.balanceOf(bob), 100);
        assertEq(wtka.totalSupply(), box.locked());
    }

    function test_onlyMinterMints() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(WrappedToken.NotMinter.selector, bob));
        wtka.mint(bob, 1);
    }

    function test_burnThenUnlock() public {
        _lock(100);
        _relay(endB, verB, B);
        vm.chainId(B);
        vm.prank(bob);
        minter.burn(40, alice);
        assertEq(wtka.totalSupply(), 60);
        assertEq(box.locked(), 100);
        _relay(endA, verA, A);
        assertEq(box.locked(), 60);
        assertEq(tka.balanceOf(alice), 240);
        assertEq(wtka.totalSupply(), box.locked());
    }

    function test_peerSetOnce() public {
        vm.expectRevert(PeerApp.PeerAlreadySet.selector);
        box.setPeer(B, bob);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(PeerApp.NotDeployer.selector, bob));
        minter.setPeer(A, bob);
    }

    // ---- 流動性プール ----

    function _pools(uint256 liquidityB) internal returns (PoolBridge poolA, PoolBridge poolB, TestToken tkb) {
        vm.chainId(A);
        poolA = new PoolBridge(outboxA, address(endA), tka);
        vm.chainId(B);
        tkb = new TestToken("Token A on B", "TKA");
        poolB = new PoolBridge(outboxB, address(endB), tkb);
        poolA.setPeer(B, address(poolB));
        poolB.setPeer(A, address(poolA));
        tkb.transfer(address(poolB), liquidityB);
    }

    function test_poolPaysFromLiquidity() public {
        (PoolBridge poolA, PoolBridge poolB, TestToken tkb) = _pools(500);
        vm.chainId(A);
        vm.startPrank(alice);
        tka.approve(address(poolA), 100);
        poolA.send(100, bob);
        vm.stopPrank();
        _relay(endB, verB, B);
        assertEq(tkb.balanceOf(bob), 100);
        assertEq(tkb.balanceOf(address(poolB)), 400);
        assertEq(tka.balanceOf(address(poolA)), 100);
    }

    function test_poolShortFailsThenRetry() public {
        (PoolBridge poolA, PoolBridge poolB, TestToken tkb) = _pools(60);
        vm.chainId(A);
        vm.startPrank(alice);
        tka.approve(address(poolA), 100);
        poolA.send(100, bob);
        vm.stopPrank();
        (bytes32 id, Message memory m) = _lastMessage();
        vm.chainId(B);
        vm.prank(attester);
        verB.attest(id);
        vm.expectEmit(true, false, false, true, address(endB));
        emit ToyEndpoint.DeliveryFailed(id, abi.encodeWithSelector(PoolBridge.InsufficientLiquidity.selector, 60, 100));
        endB.deliver(m, "");
        assertEq(endB.status(id), 2);
        tkb.transfer(address(poolB), 100);
        endB.deliver(m, "");
        assertEq(endB.status(id), 1);
        assertEq(tkb.balanceOf(bob), 100);
        assertEq(tkb.balanceOf(address(poolB)), 60);
    }
}
