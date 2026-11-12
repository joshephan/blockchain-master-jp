// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {ToyL2} from "../src/ToyL2.sol";
import {Inbox233} from "../src/Inbox233.sol";

contract Inbox233Test is Test {
    Inbox233 internal inbox;
    address internal seq = makeAddr("sequencer");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");
    address internal carol = makeAddr("carol");
    address internal dave = makeAddr("dave");
    uint256[4] internal genesis = [uint256(100), 50, 0, 0];

    function setUp() public {
        vm.warp(1_000_000);
        inbox = new Inbox233(seq, [alice, bob, carol, dave]);
    }

    /// L2ノードがすること: 決まった順番を最初から再実行
    function _derive() internal view returns (uint256[4] memory b) {
        b = genesis;
        uint256 n = inbox.entryCount();
        for (uint256 i; i < n; ++i) {
            b = ToyL2.run(b, inbox.entry(i));
        }
    }

    function test_sequencerOrders() public {
        vm.prank(seq);
        inbox.appendBatch(ToyL2.encodeTx(0, 1, 30), 0);
        uint256[4] memory b = _derive();
        assertEq(b[0], 70);
        assertEq(b[1], 80);
    }

    function test_orderDecidesWhichPasses() public {
        bytes memory toBob = ToyL2.encodeTx(0, 1, 80);
        bytes memory toCarol = ToyL2.encodeTx(0, 2, 80);
        vm.prank(seq);
        inbox.appendBatch(bytes.concat(toCarol, toBob), 0);
        uint256[4] memory b = _derive();
        assertEq(b[1], 50); // bobの分は残高不足で効果なし
        assertEq(b[2], 80);
    }

    function test_onlySequencerAppends() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Inbox233.NotSequencer.selector, alice));
        inbox.appendBatch(ToyL2.encodeTx(0, 1, 30), 0);
    }

    function test_sequencerCanSkipQueue() public {
        vm.prank(alice);
        inbox.enqueue(2, 50); // alice -> carol 50、L1に直接
        vm.startPrank(seq);
        inbox.appendBatch(ToyL2.encodeTx(1, 3, 10), 0);
        vm.warp(block.timestamp + 12 hours);
        inbox.appendBatch(ToyL2.encodeTx(1, 3, 10), 0);
        vm.stopPrank();
        uint256[4] memory b = _derive();
        assertEq(b[2], 0);
        assertEq(inbox.waitingCount(), 1);
    }

    function test_forceIncludeAfterDelay() public {
        vm.prank(alice);
        inbox.enqueue(2, 50);
        vm.warp(1_000_000 + 1 days - 1);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Inbox233.NothingDue.selector, 1_000_000 + 1 days));
        inbox.forceInclude();
        vm.warp(1_000_000 + 1 days);
        vm.prank(bob);
        assertEq(inbox.forceInclude(), 1);
        uint256[4] memory b = _derive();
        assertEq(b[0], 50);
        assertEq(b[2], 50);
        assertEq(inbox.waitingCount(), 0);
    }

    function test_sequencerTakesQueueFirst() public {
        vm.prank(alice);
        inbox.enqueue(2, 50);
        vm.prank(seq);
        inbox.appendBatch(ToyL2.encodeTx(0, 1, 80), 1);
        uint256[4] memory b = _derive();
        assertEq(b[2], 50); // キューの取引が先
        assertEq(b[1], 50); // 残りの50では80を送れない
    }

    function test_strangerCannotEnqueue() public {
        address eve = makeAddr("stranger");
        vm.prank(eve);
        vm.expectRevert(abi.encodeWithSelector(Inbox233.NotOwner.selector, eve));
        inbox.enqueue(2, 50);
    }
}
