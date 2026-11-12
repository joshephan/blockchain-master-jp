// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console, Vm} from "forge-std/Test.sol";
import {MockCoordinator} from "../src/MockCoordinator.sol";
import {Raffle} from "../src/Raffle.sol";
import {HeavyRaffle} from "../src/HeavyRaffle.sol";
import {CommitRaffle} from "../src/CommitRaffle.sol";

// 第206講: 要求・応答の二つの取引、受け取る側が守るルール、コミット・リビールの締め切りと保証金
contract Vrf206Test is Test {
    uint256 constant ORACLE_KEY = 0xA11CE5EED;
    uint256 constant N = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
    MockCoordinator coord;
    Raffle raffle;
    address p1 = address(0x1001);
    address p2 = address(0x1002);
    address p3 = address(0x1003);

    function setUp() public {
        coord = new MockCoordinator(vm.addr(ORACLE_KEY));
        raffle = new Raffle(coord);
        vm.prank(p1);
        raffle.enter();
        vm.prank(p2);
        raffle.enter();
        vm.prank(p3);
        raffle.enter();
    }

    function _sig(uint256 key, uint256 id) internal view returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, coord.digest(id));
        return abi.encodePacked(r, s, v);
    }

    // 取引一つ目: 要求(イベントだけ残り乱数なし)。3ブロック後に取引二つ目: 応答。その次に当選者
    function test_twoTransactions() public {
        raffle.draw();
        uint256 id = raffle.requestId();
        assertEq(raffle.word(), 0);
        assertEq(uint256(raffle.state()), 1);
        vm.roll(block.number + 3);
        bytes memory sig = _sig(ORACLE_KEY, id);
        coord.fulfill(id, sig);
        assertEq(raffle.word(), uint256(keccak256(sig)));
        address w = raffle.settle();
        console.log("word", raffle.word());
        console.log("winner", w);
    }

    // 要求ブロック + 3より前は応答を受け付けない
    function test_tooEarly() public {
        raffle.draw();
        uint256 id = raffle.requestId();
        uint256 reqBlock = block.number;
        vm.roll(reqBlock + 2);
        bytes memory sig = _sig(ORACLE_KEY, id);
        vm.expectRevert(abi.encodeWithSelector(MockCoordinator.TooEarly.selector, reqBlock + 2, reqBlock + 3));
        coord.fulfill(id, sig);
    }

    // 受け取る関数はコーディネーターだけが呼べる
    function test_onlyCoordinator() public {
        raffle.draw();
        vm.prank(p1);
        vm.expectRevert(abi.encodeWithSelector(Raffle.OnlyCoordinator.selector, p1, address(coord)));
        raffle.rawFulfillRandomWords(1, 7);
    }

    // オラクルの鍵でない署名、sを反転させた署名はBadProof
    function test_proofChecks() public {
        raffle.draw();
        uint256 id = raffle.requestId();
        vm.roll(block.number + 3);
        bytes memory other = _sig(0xB0B, id);
        vm.expectRevert(MockCoordinator.BadProof.selector);
        coord.fulfill(id, other);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ORACLE_KEY, coord.digest(id));
        bytes memory flipped = abi.encodePacked(r, bytes32(N - uint256(s)), v == 27 ? uint8(28) : uint8(27));
        assertEq(ecrecover(coord.digest(id), v == 27 ? 28 : 27, r, bytes32(N - uint256(s))), vm.addr(ORACLE_KEY));
        vm.expectRevert(MockCoordinator.BadProof.selector);
        coord.fulfill(id, flipped);
    }

    // 要求したあとは参加も、選び直しもない
    function test_closedAfterRequest() public {
        raffle.draw();
        vm.prank(address(0x1004));
        vm.expectRevert(abi.encodeWithSelector(Raffle.NotOpen.selector, Raffle.State.Drawing));
        raffle.enter();
        vm.expectRevert(abi.encodeWithSelector(Raffle.NotOpen.selector, Raffle.State.Drawing));
        raffle.draw();
    }

    // 受け取る関数がガスリミットに引っかかってリバートしても、要求は終わったものとして残り呼び直さない
    function test_heavyCallbackNotRetried() public {
        HeavyRaffle h = new HeavyRaffle(coord);
        for (uint160 i = 1; i <= 300; i++) {
            vm.prank(address(0x5000 + i));
            h.enter();
        }
        h.draw();
        uint256 id = h.requestId();
        vm.roll(block.number + 3);
        bytes memory sig = _sig(ORACLE_KEY, id);
        vm.recordLogs();
        coord.fulfill(id, sig);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        (, bool ok) = abi.decode(logs[logs.length - 1].data, (uint256, bool));
        assertFalse(ok);
        assertTrue(h.drawing());
        assertEq(h.winner(), address(0));
        vm.expectRevert(abi.encodeWithSelector(MockCoordinator.AlreadyFulfilled.selector, id));
        coord.fulfill(id, sig);
    }

    // コミット・リビール: 締め切り後のリビールはリバート、開かなかった人の保証金は当選者へ
    function test_commitRevealDeadlineAndDeposit() public {
        CommitRaffle cr = new CommitRaffle(1 hours, 1 hours);
        address[3] memory ps = [p1, p2, p3];
        for (uint256 i = 0; i < 3; i++) {
            vm.deal(ps[i], 1 ether);
            bytes32 h = cr.hashOf(ps[i], 100 + i, bytes32(i));
            vm.prank(ps[i]);
            cr.commit{value: 1 ether}(h);
        }
        vm.warp(block.timestamp + 1 hours);
        vm.prank(p1);
        vm.expectRevert(CommitRaffle.BadReveal.selector);
        cr.reveal(999, bytes32(0));
        vm.prank(p1);
        cr.reveal(100, bytes32(0));
        vm.prank(p2);
        cr.reveal(101, bytes32(uint256(1)));
        vm.warp(block.timestamp + 1 hours);
        bytes memory late =
            abi.encodeWithSelector(CommitRaffle.WrongPhase.selector, block.timestamp, cr.commitEnd(), cr.revealEnd());
        vm.prank(p3);
        vm.expectRevert(late);
        cr.reveal(102, bytes32(uint256(2)));
        cr.finalize();
        address w = cr.winner();
        console.log("winner", w);
        assertTrue(w == p1 || w == p2);
        assertEq(w.balance, 2 ether);
        assertEq(p3.balance, 0);
    }
}
