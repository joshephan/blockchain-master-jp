// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {BadLottery, CommitReveal} from "../src/Random175.sol";

// 第175講の作成者確認用: 同じブロックなら誰が読んでも同じ番号、ブロックの値が変わると番号も変わる
contract Random175ExtraTest is Test {
    function test_sameBlockSameNumber() public {
        BadLottery lot = new BadLottery(1000);
        vm.prank(address(0xA11CE));
        uint256 a = lot.draw();
        vm.prank(address(0xB0B));
        uint256 b = lot.draw();
        assertEq(a, b);
        emit log_named_uint("block", block.number);
        emit log_named_uint("timestamp", vm.getBlockTimestamp());
        emit log_named_uint("prevrandao", block.prevrandao);
        emit log_named_uint("alice sees", a);
        emit log_named_uint("bob sees", b);
    }

    function test_nextBlockNewNumber() public {
        BadLottery lot = new BadLottery(1000);
        uint256 first = lot.draw();
        vm.roll(block.number + 1);
        vm.warp(vm.getBlockTimestamp() + 12);
        vm.prevrandao(bytes32(uint256(2)));
        uint256 second = lot.draw();
        emit log_named_uint("this block", first);
        emit log_named_uint("next block", second);
    }

    // コミット・リビールが残すもの: 最後に開く人は、他人の秘密が開かれた後で二つの結果を両方知っている
    function test_lastRevealerSeesBoth() public {
        CommitReveal cr = new CommitReveal();
        address alice = address(0xA11CE);
        address bob = address(0xB0B);
        vm.prank(alice);
        cr.commit(keccak256(abi.encodePacked(uint256(111), alice)));
        vm.prank(bob);
        cr.commit(keccak256(abi.encodePacked(uint256(222), bob)));

        vm.prank(alice);
        cr.reveal(111);
        // bobが開かないと
        emit log_named_uint("if bob stays closed", cr.result(1000));
        emit log_named_uint("revealCount", cr.revealCount());
        // bobが開くと
        vm.prank(bob);
        cr.reveal(222);
        emit log_named_uint("if bob reveals", cr.result(1000));
        emit log_named_uint("revealCount", cr.revealCount());
    }
}
