// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {console2} from "forge-std/console2.sol";
import {OpBase} from "./OpBase.sol";
import {EntryPoint219} from "../src/EntryPoint219.sol";
import {Account219} from "../src/Account219.sol";
import {SponsorPaymaster220, TokenPaymaster220, ITokenLike} from "../src/Paymaster220.sol";
import {PackedUserOperation, PostOpMode} from "../src/UserOp.sol";

contract Paymaster220Test is OpBase {
    SponsorPaymaster220 internal sponsorPm;
    TokenPaymaster220 internal tokenPm;
    uint256 internal sponsorKey = 0x5B0;
    uint128 internal constant PM_VERIFICATION_GAS = 100_000;
    uint128 internal constant PM_POSTOP_GAS = 100_000;

    function setUp() public {
        _setUpAA(); // アカウントのアドレスのETHは0、EntryPointへの預け金は0
        sponsorPm = new SponsorPaymaster220(address(ep), vm.addr(sponsorKey));
        sponsorPm.deposit{value: 1 ether}();
        tokenPm = new TokenPaymaster220(address(ep), ITokenLike(address(token)), 2000 ether);
        tokenPm.deposit{value: 1 ether}();
    }

    // 肩代わりの署名を付けたUserOperation: 肩代わりする側が先、持ち主があとで署名
    function _sponsored(uint256 nonce, bytes memory callData, address signedSender, uint48 validUntil, uint256 key)
        internal
        view
        returns (PackedUserOperation memory op)
    {
        op = _op(nonce, callData, "");
        address realSender = op.sender;
        op.sender = signedSender;
        bytes32 h = sponsorPm.getHash(op, validUntil, 0);
        op.sender = realSender;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, h);
        op.paymasterAndData = abi.encodePacked(
            address(sponsorPm), PM_VERIFICATION_GAS, uint128(0), validUntil, uint48(0), abi.encodePacked(r, s, v)
        );
        op = _sign(op, ownerKey);
    }

    function _send(PackedUserOperation memory op, string memory reason) internal {
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = op;
        vm.expectRevert(abi.encodeWithSelector(EntryPoint219.FailedOp.selector, 0, reason));
        vm.prank(bundler, bundler);
        ep.handleOps(ops, beneficiary);
    }

    // アカウントはETH 0でMarketに預ける。ガスはペイマスターの預け金から
    function test_sponsoredOpAccountPaysNothing() public {
        PackedUserOperation memory op = _sponsored(0, _depositCall(100), address(acct), 0, sponsorKey);
        vm.recordLogs();
        _bundle(op);
        (bool success, uint256 cost,) = _lastOpEvent();
        assertTrue(success);
        assertEq(_deposited(address(acct)), 100);
        assertEq(address(acct).balance, 0);
        assertEq(ep.balanceOf(address(acct)), 0);
        assertEq(ep.balanceOf(address(sponsorPm)), 1 ether - cost);
        assertEq(beneficiary.balance, cost);
        console2.log("sponsored cost", cost);
    }

    // 別のアカウント宛てにもらった肩代わりの署名はAA34
    function test_sponsorSigForOtherSenderRejected() public {
        PackedUserOperation memory op = _sponsored(0, _depositCall(100), makeAddr("other"), 0, sponsorKey);
        _send(op, "AA34 signature error");
    }

    // 肩代わりの署名の鍵でない鍵で署名するとAA34
    function test_sponsorSigWrongKeyRejected() public {
        PackedUserOperation memory op = _sponsored(0, _depositCall(100), address(acct), 0, 0xBAD);
        _send(op, "AA34 signature error");
    }

    // 期限が切れた肩代わりの署名はAA32
    function test_sponsorSigExpiredRejected() public {
        vm.warp(1_000_000);
        PackedUserOperation memory op = _sponsored(0, _depositCall(100), address(acct), 999_999, sponsorKey);
        _send(op, "AA32 paymaster expired or not due");
    }

    // 一度使った肩代わりの署名を次のナンスに付け直すとAA34
    function test_sponsorSigNotReusable() public {
        PackedUserOperation memory first = _sponsored(0, _depositCall(100), address(acct), 0, sponsorKey);
        _bundle(first);
        PackedUserOperation memory again = _op(1, _depositCall(100), first.paymasterAndData);
        again = _sign(again, ownerKey);
        _send(again, "AA34 signature error");
        assertEq(_deposited(address(acct)), 100);
    }

    // ペイマスターの預け金が最大コストより少なければAA31
    function test_paymasterDepositTooLowRejected() public {
        SponsorPaymaster220 poor = new SponsorPaymaster220(address(ep), vm.addr(sponsorKey));
        poor.deposit{value: 1 gwei}();
        sponsorPm = poor;
        PackedUserOperation memory op = _sponsored(0, _depositCall(100), address(acct), 0, sponsorKey);
        _send(op, "AA31 paymaster deposit too low");
    }

    // ペイマスターの検証関数はEntryPointだけが呼ぶ
    function test_onlyEntryPointCallsPaymaster() public {
        PackedUserOperation memory op = _sponsored(0, _depositCall(100), address(acct), 0, sponsorKey);
        vm.expectRevert(SponsorPaymaster220.NotEntryPoint.selector);
        sponsorPm.validatePaymasterUserOp(op, bytes32(0), 0);
        vm.expectRevert(TokenPaymaster220.NotEntryPoint.selector);
        tokenPm.postOp(PostOpMode.opSucceeded, abi.encode(address(acct), uint256(1)), 0, 0);
    }

    function _tokenOp(uint256 nonce, bytes memory callData) internal view returns (PackedUserOperation memory) {
        bytes memory pm = abi.encodePacked(address(tokenPm), PM_VERIFICATION_GAS, PM_POSTOP_GAS);
        return _sign(_op(nonce, callData, pm), ownerKey);
    }

    // トークンで払う: 検証で最大コスト分のトークンを先に受け取り、postOpで残った分を返す
    function test_tokenPaymasterPrechargeRefund() public {
        token.transfer(address(acct), 100 ether);
        vm.prank(address(acct)); // 前のUserOperationでペイマスターに承認したことにする
        token.approve(address(tokenPm), type(uint256).max);
        uint256 before = token.balanceOf(address(acct));
        uint256 prefund = (uint256(VERIFICATION_GAS) + CALL_GAS + PM_VERIFICATION_GAS + PM_POSTOP_GAS
                + PRE_VERIFICATION_GAS) * MAX_FEE;
        vm.recordLogs();
        _bundle(_tokenOp(0, _depositCall(100)));
        (bool success, uint256 cost,) = _lastOpEvent();
        assertTrue(success);
        uint256 paidTokens = before - 100 - token.balanceOf(address(acct));
        assertEq(address(acct).balance, 0);
        assertEq(ep.balanceOf(address(tokenPm)), 1 ether - cost);
        assertLe(paidTokens, tokenPm.toTokens(prefund));
        console2.log("prefund wei", prefund);
        console2.log("max tokens", tokenPm.toTokens(prefund));
        console2.log("actualGasCost wei", cost);
        console2.log("tokens paid", paidTokens);
        console2.log("tokens for cost", tokenPm.toTokens(cost));
    }

    // 実行がリバートしてもpostOpは呼ばれ、トークンを受け取る
    function test_tokenPaymasterChargesRevertedOp() public {
        token.transfer(address(acct), 100 ether);
        vm.prank(address(acct));
        token.approve(address(tokenPm), type(uint256).max);
        uint256 before = token.balanceOf(address(acct));
        vm.recordLogs();
        _bundle(_tokenOp(0, _depositCall(0)));
        (bool success,,) = _lastOpEvent();
        assertFalse(success);
        assertGt(before - token.balanceOf(address(acct)), 0);
        assertEq(_deposited(address(acct)), 0);
        console2.log("tokens paid on revert", before - token.balanceOf(address(acct)));
    }

    // ペイマスターに承認していないアカウント: 検証でリバートしてAA33
    function test_tokenPaymasterWithoutApprovalRejected() public {
        token.transfer(address(acct), 100 ether);
        _send(_tokenOp(0, _depositCall(100)), "AA33 reverted");
    }
}
