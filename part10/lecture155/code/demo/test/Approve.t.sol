// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, Vm, console} from "forge-std/Test.sol";
import {StdToken} from "../src/StdToken.sol";
import {OzToken} from "../src/OzToken.sol";
import {Puller, SelfPuller, IToken} from "../src/Puller.sol";

contract ApproveTest is Test {
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    // 同じ承認の欄を二回書く間に、使う側が先に使う: 100 + 50
    function test_overwriteRace() public {
        StdToken t = new StdToken("Std Token", "STD", 18, 1000);
        t.transfer(alice, 1000);
        vm.prank(alice);
        t.approve(bob, 100);
        vm.prank(bob);
        t.transferFrom(alice, bob, 100); // aliceのapprove(bob, 50)より先に入る
        vm.prank(alice);
        t.approve(bob, 50);
        vm.prank(bob);
        t.transferFrom(alice, bob, 50);
        assertEq(t.balanceOf(bob), 150);
    }

    // 先に0に変えてもallowanceは0。その間に使われたかはTransferのログでしか分からない
    function test_zeroFirstLooksSame() public {
        StdToken t = new StdToken("Std Token", "STD", 18, 1000);
        t.transfer(alice, 1000);
        vm.prank(alice);
        t.approve(bob, 100);
        vm.prank(bob);
        t.transferFrom(alice, bob, 100);
        vm.prank(alice);
        t.approve(bob, 0);
        assertEq(t.allowance(alice, bob), 0);

        StdToken u = new StdToken("Std Token", "STD", 18, 1000);
        u.transfer(alice, 1000);
        vm.prank(alice);
        u.approve(bob, 100);
        vm.prank(alice);
        u.approve(bob, 0);
        assertEq(u.allowance(alice, bob), 0);
    }

    // OZ 5.4.0: 最大値の承認はtransferFromで減らず、Approvalも出さない
    function test_ozMaxAllowance() public {
        OzToken t = new OzToken(1000);
        t.transfer(alice, 1000);
        vm.prank(alice);
        t.approve(bob, type(uint256).max);
        vm.recordLogs();
        vm.prank(bob);
        t.transferFrom(alice, bob, 300);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        console.log("logs", logs.length);
        assertEq(t.allowance(alice, bob), type(uint256).max);
    }

    // OZ 5.4.0: 普通の承認は減るが、transferFromはApprovalを出さない
    function test_ozSpendNoApprovalEvent() public {
        OzToken t = new OzToken(1000);
        t.transfer(alice, 1000);
        vm.prank(alice);
        t.approve(bob, 500);
        vm.recordLogs();
        vm.prank(bob);
        t.transferFrom(alice, bob, 300);
        Vm.Log[] memory logs = vm.getRecordedLogs();
        console.log("logs", logs.length);
        console.logBytes32(logs[0].topics[0]);
        console.log("allowance", t.allowance(alice, bob));
    }

    // StdTokenはtransferFromでApprovalを出さない(EIP-20はapproveでのみMUST)
    function test_stdSpendEvents() public {
        StdToken t = new StdToken("Std Token", "STD", 18, 1000);
        t.transfer(alice, 1000);
        vm.prank(alice);
        t.approve(bob, 500);
        vm.recordLogs();
        vm.prank(bob);
        t.transferFrom(alice, bob, 300);
        console.log("logs", vm.getRecordedLogs().length);
    }

    // fromを引数で受け取るPuller: aliceが承認した分をbobが持っていく
    function test_pullerTakesOthers() public {
        StdToken t = new StdToken("Std Token", "STD", 18, 1000);
        Puller p = new Puller();
        t.transfer(alice, 1000);
        vm.prank(alice);
        t.approve(address(p), 100);
        vm.prank(bob);
        p.pull(IToken(address(t)), alice, 100);
        assertEq(t.balanceOf(bob), 100);
    }

    // 呼んだ人のものだけを移すSelfPuller: bobが呼んでもbobの残高からだけ
    function test_selfPullerOnlyCaller() public {
        StdToken t = new StdToken("Std Token", "STD", 18, 1000);
        SelfPuller p = new SelfPuller();
        t.transfer(alice, 1000);
        vm.prank(alice);
        t.approve(address(p), 100);
        vm.prank(bob);
        vm.expectRevert(bytes("insufficient allowance"));
        p.pullMine(IToken(address(t)), 100);
        assertEq(t.allowance(alice, address(p)), 100);
    }

    // 0の移転もTransferを出す(EIP-20 MUST)
    function test_zeroTransferEmits() public {
        StdToken t = new StdToken("Std Token", "STD", 18, 1000);
        OzToken o = new OzToken(1000);
        vm.recordLogs();
        t.transfer(bob, 0);
        o.transfer(bob, 0);
        console.log("logs", vm.getRecordedLogs().length);
    }

    function test_decimals() public {
        StdToken six = new StdToken("Six", "SIX", 6, 1_000_000);
        StdToken eighteen = new StdToken("Eighteen", "EIG", 18, 1e18);
        console.log(six.decimals(), six.totalSupply());
        console.log(eighteen.decimals(), eighteen.totalSupply());
    }
}
