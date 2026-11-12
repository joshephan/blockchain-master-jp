// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {PushPayout, PullPayout, Rejecter, Ignorer} from "../src/Payout170.sol";

contract Payout170Test is Test {
    // push: 受け取りを拒否する受取人一人が全体の支払いを止める
    function test_pushBlockedByOne() public {
        PushPayout push = new PushPayout();
        push.addRecipient(address(0xA11CE));
        push.addRecipient(address(new Rejecter())); // 受け取りを拒否
        push.addRecipient(address(0xB0B));

        vm.deal(address(this), 3 ether);
        vm.expectRevert(bytes("one recipient blocked all"));
        push.payAll{value: 3 ether}();
    }

    // pull: 同じ受取人三人でも、拒否者は自分の分だけを引き出せず、残りは各自が引き出す
    function test_pullUnaffected() public {
        PullPayout pull = new PullPayout();
        pull.addRecipient(address(0xA11CE));
        Rejecter r = new Rejecter();
        pull.addRecipient(address(r));
        pull.addRecipient(address(0xB0B));

        vm.deal(address(this), 3 ether);
        pull.fund{value: 3 ether}();

        // 拒否者の分はwithdrawで巻き戻る(止まってもその人の分だけ)
        vm.prank(address(r));
        vm.expectRevert(bytes("send failed"));
        pull.withdraw();

        // 残りは問題なく引き出せる
        vm.prank(address(0xA11CE));
        pull.withdraw();
        assertEq(address(0xA11CE).balance, 1 ether);
        assertEq(pull.owed(address(0xA11CE)), 0);
        assertEq(pull.owed(address(r)), 1 ether); // 拒否者の分は帳簿にそのまま残る
    }

    // 結果を見ない低水準のcall: 失敗してもdoneがtrueになる
    function test_ignoredCallResult() public {
        Ignorer ig = new Ignorer();
        vm.deal(address(ig), 1 ether);
        Rejecter r = new Rejecter();
        ig.pay(address(r), 1 ether); // 受け取る側が巻き戻してもig.payは成功で終わる
        assertTrue(ig.done());
        assertEq(address(r).balance, 0); // 実際には一銭も届いていない
    }
}
