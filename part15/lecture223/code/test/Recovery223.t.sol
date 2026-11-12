// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {console2} from "forge-std/console2.sol";
import {Base} from "./Base.sol";
import {EntryPoint219} from "../src/EntryPoint219.sol";
import {Recovery223} from "../src/Recovery223.sol";
import {PackedUserOperation} from "../src/UserOp.sol";

contract Recovery223Test is Base {
    EntryPoint219 internal ep;
    Recovery223 internal acct;
    uint256 internal ownerKey = 0xA11CE;
    uint256 internal newKey = 0xB0B;
    uint256[3] internal gKeys = [uint256(0x6A1), 0x6A2, 0x6A3];
    address[] internal guardians;
    address internal bundler = makeAddr("bundler");

    function setUp() public {
        _setUpMarket();
        vm.fee(1 gwei);
        vm.warp(1_000_000);
        ep = new EntryPoint219();
        for (uint256 i = 0; i < 3; i++) {
            guardians.push(vm.addr(gKeys[i]));
        }
        acct = new Recovery223(address(ep), vm.addr(ownerKey), guardians, 2, 2 days);
        token.transfer(address(acct), 500);
        vm.deal(address(acct), 1 ether);
        vm.deal(bundler, 1 ether);
    }

    // 選んだ保護者の鍵の署名を署名者アドレスの昇順で
    function _sigs(Recovery223 a, address newOwner, uint256[] memory keys) internal view returns (bytes[] memory sigs) {
        for (uint256 i = 0; i < keys.length; i++) {
            for (uint256 j = i + 1; j < keys.length; j++) {
                if (vm.addr(keys[j]) < vm.addr(keys[i])) (keys[i], keys[j]) = (keys[j], keys[i]);
            }
        }
        sigs = new bytes[](keys.length);
        bytes32 d = a.recoveryDigest(newOwner);
        for (uint256 i = 0; i < keys.length; i++) {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(keys[i], d);
            sigs[i] = abi.encodePacked(r, s, v);
        }
    }

    function _two() internal view returns (uint256[] memory k) {
        k = new uint256[](2);
        k[0] = gKeys[0];
        k[1] = gKeys[2];
    }

    function _op(uint256 nonce, bytes memory callData, uint256 key)
        internal
        view
        returns (PackedUserOperation memory op)
    {
        op.sender = address(acct);
        op.nonce = nonce;
        op.callData = callData;
        op.accountGasLimits = bytes32((uint256(200_000) << 128) | 300_000);
        op.preVerificationGas = 50_000;
        op.gasFees = bytes32((uint256(1 gwei) << 128) | 3 gwei);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, ep.getUserOpHash(op));
        op.signature = abi.encodePacked(r, s, v);
    }

    function _bundle(PackedUserOperation memory op) internal {
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = op;
        vm.prank(bundler, bundler);
        ep.handleOps(ops, payable(bundler));
    }

    function _transferOp(uint256 nonce, uint256 key) internal view returns (PackedUserOperation memory) {
        bytes memory cd = abi.encodeCall(
            Recovery223.execute, (address(token), 0, abi.encodeCall(token.transfer, (vm.addr(newKey), 100)))
        );
        return _op(nonce, cd, key);
    }

    function test_twoGuardiansStartRecovery() public {
        acct.startRecovery(vm.addr(newKey), _sigs(acct, vm.addr(newKey), _two()));
        (address n, uint64 readyAt) = acct.pending();
        assertEq(n, vm.addr(newKey));
        assertEq(readyAt, 1_000_000 + 2 days);
        assertEq(acct.owner(), vm.addr(ownerKey));
        assertEq(acct.recoveryNonce(), 1);
    }

    function test_oneGuardianNotEnough() public {
        uint256[] memory k = new uint256[](1);
        k[0] = gKeys[1];
        bytes[] memory sigs = _sigs(acct, vm.addr(newKey), k);
        vm.expectRevert(abi.encodeWithSelector(Recovery223.NotEnoughGuardians.selector, 1, 2));
        acct.startRecovery(vm.addr(newKey), sigs);
    }

    function test_sameGuardianTwiceRejected() public {
        uint256[] memory k = new uint256[](1);
        k[0] = gKeys[1];
        bytes[] memory one = _sigs(acct, vm.addr(newKey), k);
        bytes[] memory sigs = new bytes[](2);
        sigs[0] = one[0];
        sigs[1] = one[0];
        vm.expectRevert(Recovery223.GuardiansNotSorted.selector);
        acct.startRecovery(vm.addr(newKey), sigs);
    }

    function test_nonGuardianSigRejected() public {
        uint256[] memory k = new uint256[](2);
        k[0] = gKeys[0];
        k[1] = 0xBAD;
        bytes[] memory sigs = _sigs(acct, vm.addr(newKey), k);
        vm.expectRevert(abi.encodeWithSelector(Recovery223.NotGuardian.selector, vm.addr(0xBAD)));
        acct.startRecovery(vm.addr(newKey), sigs);
    }

    function test_finishBeforeDelayRejected() public {
        acct.startRecovery(vm.addr(newKey), _sigs(acct, vm.addr(newKey), _two()));
        vm.warp(1_000_000 + 2 days - 1);
        vm.expectRevert(abi.encodeWithSelector(Recovery223.RecoveryNotReady.selector, uint64(1_000_000 + 2 days)));
        acct.finishRecovery();
    }

    // 待ったあと持ち主を交代。古い鍵のUserOperationはAA24、新しい鍵は通過
    function test_finishAfterDelayChangesOwner() public {
        acct.startRecovery(vm.addr(newKey), _sigs(acct, vm.addr(newKey), _two()));
        vm.warp(1_000_000 + 2 days);
        acct.finishRecovery();
        assertEq(acct.owner(), vm.addr(newKey));
        PackedUserOperation memory oldOp = _transferOp(0, ownerKey);
        vm.expectRevert(abi.encodeWithSelector(EntryPoint219.FailedOp.selector, 0, "AA24 signature error"));
        _bundle(oldOp);
        _bundle(_transferOp(0, newKey));
        assertEq(token.balanceOf(vm.addr(newKey)), 100);
    }

    // 待っているあいだに持ち主の鍵が取り消す
    function test_ownerCancelsDuringDelay() public {
        acct.startRecovery(vm.addr(newKey), _sigs(acct, vm.addr(newKey), _two()));
        bytes memory cd =
            abi.encodeCall(Recovery223.execute, (address(acct), 0, abi.encodeCall(Recovery223.cancelRecovery, ())));
        _bundle(_op(0, cd, ownerKey));
        (, uint64 readyAt) = acct.pending();
        assertEq(readyAt, 0);
        vm.warp(1_000_000 + 2 days);
        vm.expectRevert(Recovery223.NoPendingRecovery.selector);
        acct.finishRecovery();
        assertEq(acct.owner(), vm.addr(ownerKey));
    }

    // 一度使った保護者の署名は次の復旧にはもう合わない(復旧の使用番号が上がる)
    function test_sigsNotReusable() public {
        bytes[] memory sigs = _sigs(acct, vm.addr(newKey), _two());
        acct.startRecovery(vm.addr(newKey), sigs);
        bytes memory cd =
            abi.encodeCall(Recovery223.execute, (address(acct), 0, abi.encodeCall(Recovery223.cancelRecovery, ())));
        _bundle(_op(0, cd, ownerKey));
        vm.expectPartialRevert(Recovery223.NotGuardian.selector);
        acct.startRecovery(vm.addr(newKey), sigs);
    }

    // 同じ保護者を置いた別のアカウントには合わない
    function test_sigsForOtherAccountRejected() public {
        Recovery223 other = new Recovery223(address(ep), vm.addr(ownerKey), guardians, 2, 2 days);
        bytes[] memory sigs = _sigs(acct, vm.addr(newKey), _two());
        vm.expectPartialRevert(Recovery223.NotGuardian.selector);
        other.startRecovery(vm.addr(newKey), sigs);
    }

    // 保護者の鍵ではアカウントのお金を動かせない
    function test_guardianCannotMoveFunds() public {
        PackedUserOperation memory gOp = _transferOp(0, gKeys[0]);
        vm.expectRevert(abi.encodeWithSelector(EntryPoint219.FailedOp.selector, 0, "AA24 signature error"));
        _bundle(gOp);
        assertEq(token.balanceOf(address(acct)), 500);
    }

    function test_printDigest() public view {
        console2.log("guardian 0", guardians[0]);
        console2.log("guardian 1", guardians[1]);
        console2.log("guardian 2", guardians[2]);
        console2.logBytes32(acct.recoveryDigest(vm.addr(newKey)));
    }
}
