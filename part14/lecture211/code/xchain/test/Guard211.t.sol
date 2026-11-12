// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Base57} from "./Base57.sol";
import {Message} from "../src/Msg57.sol";
import {ToyOutbox} from "../src/Outbox57.sol";
import {ToyEndpoint} from "../src/Endpoint57.sol";
import {AttesterVerifier} from "../src/Verifiers57.sol";
import {TestToken, LockBox, Minter, WrappedToken} from "../src/Assets57.sol";

// 第211講: ミント側の1日の上限と一時停止。止められたメッセージは受け取り側の失敗として残り、解除後に入れ直すと発行される
contract GuardTest is Base57 {
    ToyOutbox outboxA;
    ToyOutbox outboxB;
    AttesterVerifier verB;
    ToyEndpoint endB;
    TestToken tka;
    LockBox box;
    Minter minter;
    WrappedToken wtka;
    address attester = makeAddr("attester");
    address guardian = makeAddr("guardian");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        vm.chainId(A);
        outboxA = new ToyOutbox();
        tka = new TestToken("Token A", "TKA");
        vm.chainId(B);
        outboxB = new ToyOutbox();
        verB = new AttesterVerifier(attester);
        endB = new ToyEndpoint(verB, _one(A), _oneAddr(address(outboxA)));
        minter = new Minter(outboxB, address(endB), 150, guardian);
        wtka = minter.wrapped();
        vm.chainId(A);
        box = new LockBox(outboxA, address(endB), tka);
        box.setPeer(B, address(minter));
        minter.setPeer(A, address(box));
        tka.transfer(alice, 300);
        vm.recordLogs();
    }

    function _lockAndAttest(uint256 amount) internal returns (bytes32 id, Message memory m) {
        vm.chainId(A);
        vm.startPrank(alice);
        tka.approve(address(box), amount);
        box.lock(amount, bob);
        vm.stopPrank();
        (id, m) = _lastMessage();
        vm.chainId(B);
        vm.prank(attester);
        verB.attest(id);
    }

    function test_dailyCapDefers() public {
        (, Message memory m1) = _lockAndAttest(100);
        endB.deliver(m1, "");
        (bytes32 id2, Message memory m2) = _lockAndAttest(100);
        vm.expectEmit(true, false, false, true, address(endB));
        emit ToyEndpoint.DeliveryFailed(id2, abi.encodeWithSelector(Minter.MintCapExceeded.selector, 200, 150));
        endB.deliver(m2, "");
        assertEq(wtka.totalSupply(), 100);
        assertEq(box.locked(), 200);
        vm.warp(block.timestamp + 1 days);
        endB.deliver(m2, "");
        assertEq(endB.status(id2), 1);
        assertEq(wtka.totalSupply(), box.locked());
    }

    function test_pauseDefersMint() public {
        vm.prank(guardian);
        minter.setPaused(true);
        (bytes32 id, Message memory m) = _lockAndAttest(100);
        vm.expectEmit(true, false, false, true, address(endB));
        emit ToyEndpoint.DeliveryFailed(id, abi.encodeWithSelector(Minter.Paused.selector));
        endB.deliver(m, "");
        assertEq(wtka.totalSupply(), 0);
        vm.prank(guardian);
        minter.setPaused(false);
        endB.deliver(m, "");
        assertEq(wtka.balanceOf(bob), 100);
    }

    function test_strangerCannotPause() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Minter.NotGuardian.selector, bob));
        minter.setPaused(true);
    }
}
