// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {BadLottery, CommitReveal} from "../src/Random175.sol";

contract Random175Test is Test {
    // 間違った番号は巻き戻る(攻撃者は負ける回には参加しない)
    function test_revertOnMiss() public {
        BadLottery lot = new BadLottery(1000);
        uint256 win = lot.draw();
        uint256 wrong = win == 0 ? 1 : win - 1;
        vm.expectRevert(BadLottery.Missed.selector);
        lot.play(wrong);
    }

    // まだ作られていないブロックのハッシュは0
    function test_futureHashZero() public {
        BadLottery lot = new BadLottery(1000);
        assertEq(lot.futureHash(), bytes32(0));
    }

    // コミット・リビール: 上げたハッシュは秘密を明かさず、間違った秘密は巻き戻る
    function test_commitRevealFlow() public {
        CommitReveal cr = new CommitReveal();
        uint256 secretA = 111;
        uint256 secretB = 222;
        address alice = address(0xA11CE);
        address bob = address(0xB0B);

        vm.prank(alice);
        cr.commit(keccak256(abi.encodePacked(secretA, alice)));
        vm.prank(bob);
        cr.commit(keccak256(abi.encodePacked(secretB, bob)));

        // リビールの前は、混ぜた値がまだ0(誰も決められない)
        assertEq(cr.seed(), 0);

        // 間違った秘密は巻き戻る
        vm.prank(alice);
        vm.expectRevert(CommitReveal.BadReveal.selector);
        cr.reveal(999);

        vm.prank(alice);
        cr.reveal(secretA);
        vm.prank(bob);
        cr.reveal(secretB);

        assertEq(cr.revealCount(), 2);
        assertEq(cr.seed(), secretA ^ secretB);
        emit log_named_uint("result", cr.result(1000));
    }
}
