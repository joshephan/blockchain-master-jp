// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {console2} from "forge-std/console2.sol";
import {OpBase} from "./OpBase.sol";
import {EntryPoint219} from "../src/EntryPoint219.sol";
import {Account219} from "../src/Account219.sol";
import {PackedUserOperation} from "../src/UserOp.sol";

contract EntryPoint219Test is OpBase {
    function setUp() public {
        _setUpAA();
        vm.deal(address(acct), 1 ether); // アカウントのアドレスにETH。持ち主の鍵(owner)は0
    }

    // 承認 + Marketへの預け入れをUserOperation一つで。ガスはアカウントがEntryPointに預けたお金から
    function test_handleOpsDepositsToMarket() public {
        PackedUserOperation memory op = _sign(_op(0, _depositCall(100), ""), ownerKey);
        uint256 prefund = (uint256(VERIFICATION_GAS) + CALL_GAS + PRE_VERIFICATION_GAS) * MAX_FEE;
        vm.recordLogs();
        _bundle(op);
        (bool success, uint256 cost, uint256 used) = _lastOpEvent();
        assertTrue(success);
        assertEq(_deposited(address(acct)), 100);
        assertEq(address(acct).balance, 1 ether - prefund);
        assertEq(ep.balanceOf(address(acct)), prefund - cost);
        assertEq(beneficiary.balance, cost);
        assertEq(owner.balance, 0);
        assertEq(ep.getNonce(address(acct), 0), 1);
        console2.log("prefund", prefund);
        console2.log("actualGasCost", cost);
        console2.log("actualGasUsed", used);
        console2.log("deposit left", ep.balanceOf(address(acct)));
    }

    // userOpHash: チェーン番号とEntryPointのアドレスが入る、signatureの欄は入らない
    function test_userOpHashBindsChainAndEntryPoint() public {
        PackedUserOperation memory op = _op(0, _depositCall(100), "");
        bytes32 h = ep.getUserOpHash(op);
        EntryPoint219 other = new EntryPoint219();
        bytes32 hOtherEp = other.getUserOpHash(op);
        uint256 here = vm.getChainId();
        vm.chainId(1);
        bytes32 hOtherChain = ep.getUserOpHash(op);
        vm.chainId(here);
        op.signature = hex"1234";
        bytes32 hSig = ep.getUserOpHash(op);
        assertTrue(h != hOtherEp);
        assertTrue(h != hOtherChain);
        assertEq(h, hSig);
        console2.logBytes32(h);
        console2.logBytes32(hOtherEp);
        console2.logBytes32(hOtherChain);
    }

    // 別の鍵で署名: アカウントは1を返し、EntryPointがAA24でバンドルをリバート
    function test_badSignatureRejected() public {
        PackedUserOperation memory op = _sign(_op(0, _depositCall(100), ""), 0xB0B);
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = op;
        vm.expectRevert(abi.encodeWithSelector(EntryPoint219.FailedOp.selector, 0, "AA24 signature error"));
        vm.prank(bundler, bundler);
        ep.handleOps(ops, beneficiary);
    }

    // 同じUserOperationをもう一度出すとAA25
    function test_sameOpTwiceRejected() public {
        PackedUserOperation memory op = _sign(_op(0, _depositCall(100), ""), ownerKey);
        _bundle(op);
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = op;
        vm.expectRevert(abi.encodeWithSelector(EntryPoint219.FailedOp.selector, 0, "AA25 invalid account nonce"));
        vm.prank(bundler, bundler);
        ep.handleOps(ops, beneficiary);
        assertEq(_deposited(address(acct)), 100);
    }

    // 別のチェーン番号で作った署名はこのチェーンでAA24
    function test_otherChainSigRejected() public {
        PackedUserOperation memory op = _op(0, _depositCall(100), "");
        uint256 here = vm.getChainId();
        vm.chainId(1);
        op = _sign(op, ownerKey);
        vm.chainId(here);
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = op;
        vm.expectRevert(abi.encodeWithSelector(EntryPoint219.FailedOp.selector, 0, "AA24 signature error"));
        vm.prank(bundler, bundler);
        ep.handleOps(ops, beneficiary);
    }

    // アカウントのexecuteはEntryPointだけが呼ぶ
    function test_onlyEntryPointExecutes() public {
        vm.expectRevert(Account219.NotEntryPoint.selector);
        vm.prank(bundler);
        acct.execute(address(token), 0, abi.encodeCall(token.transfer, (bundler, 100)));
    }

    // ナンスのkeyが違えばsequenceを別に数える
    function test_nonceKeysIndependent() public {
        uint256 keyOne = uint256(1) << 64;
        _bundle(_sign(_op(keyOne, _depositCall(10), ""), ownerKey));
        assertEq(ep.getNonce(address(acct), 1), keyOne | 1);
        assertEq(ep.getNonce(address(acct), 0), 0);
        _bundle(_sign(_op(0, _depositCall(20), ""), ownerKey));
        assertEq(_deposited(address(acct)), 30);
    }

    // 実行がリバートしても(Market ZeroAmount)、検証を通ったUserOperationはガスを払う
    function test_executionRevertStillCharges() public {
        PackedUserOperation memory op = _sign(_op(0, _depositCall(0), ""), ownerKey);
        vm.recordLogs();
        _bundle(op);
        (bool success, uint256 cost,) = _lastOpEvent();
        assertFalse(success);
        assertGt(cost, 0);
        assertEq(beneficiary.balance, cost);
        assertEq(_deposited(address(acct)), 0);
        assertEq(ep.getNonce(address(acct), 0), 1);
        console2.log("reverted op cost", cost);
    }

    // アカウントにETHも預け金もなければAA21
    function test_noFundsRejected() public {
        vm.deal(address(acct), 0);
        PackedUserOperation memory op = _sign(_op(0, _depositCall(100), ""), ownerKey);
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = op;
        vm.expectRevert(abi.encodeWithSelector(EntryPoint219.FailedOp.selector, 0, "AA21 didn't pay prefund"));
        vm.prank(bundler, bundler);
        ep.handleOps(ops, beneficiary);
    }
}
