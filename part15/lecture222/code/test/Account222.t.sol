// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {console2} from "forge-std/console2.sol";
import {Base} from "./Base.sol";
import {EntryPoint219} from "../src/EntryPoint219.sol";
import {Account222} from "../src/Account222.sol";
import {PackedUserOperation} from "../src/UserOp.sol";

contract Account222Test is Base {
    EntryPoint219 internal ep;
    Account222 internal acct;
    uint256 internal ownerKey = 0xA11CE;
    uint256 internal sessionKey = 0x5E55;
    address internal sess;
    address internal bundler = makeAddr("bundler");
    uint48 internal constant START = 1_000_000;
    uint48 internal constant END = 1_000_000 + 1 days;

    function setUp() public {
        _setUpMarket();
        vm.fee(1 gwei);
        vm.warp(START);
        ep = new EntryPoint219();
        acct = new Account222(address(ep), vm.addr(ownerKey));
        sess = vm.addr(sessionKey);
        token.transfer(address(acct), 1000);
        vm.deal(address(acct), 1 ether);
        vm.deal(bundler, 1 ether);
        vm.prank(address(acct));
        token.approve(address(market), type(uint256).max); // 持ち主が先に与えた承認(テストを短く)
        _addSession(300);
    }

    function _scope(uint128 limit) internal view returns (Account222.Session memory s) {
        s.target = address(market);
        s.selector = market.deposit.selector;
        s.asset = address(token);
        s.limit = limit;
        s.validAfter = START;
        s.validUntil = END;
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

    function _sessNonce(uint64 seq) internal view returns (uint256) {
        return (uint256(uint160(sess)) << 64) | seq;
    }

    function _deposit(uint256 amount) internal view returns (bytes memory) {
        return abi.encodeCall(
            Account222.execute, (address(market), 0, abi.encodeCall(market.deposit, (address(token), amount)))
        );
    }

    function _addSession(uint128 limit) internal {
        bytes memory inner = abi.encodeCall(Account222.addSession, (sess, _scope(limit)));
        uint256 n = ep.getNonce(address(acct), 0);
        _bundle(_op(n, abi.encodeCall(Account222.execute, (address(acct), 0, inner)), ownerKey));
    }

    function _expectFail(PackedUserOperation memory op, string memory reason) internal {
        vm.expectRevert(abi.encodeWithSelector(EntryPoint219.FailedOp.selector, 0, reason));
        _bundle(op);
    }

    // 持ち主が署名したUserOperation一つで範囲を記録する。記録した値はcalldataの中に全部ある
    function test_ownerAddsSession() public view {
        (address target, bytes4 selector, address asset, uint128 limit, uint128 spent, uint48 va, uint48 vu) =
            acct.sessions(sess);
        assertEq(target, address(market));
        assertEq(selector, market.deposit.selector);
        assertEq(asset, address(token));
        assertEq(limit, 300);
        assertEq(spent, 0);
        assertEq(va, START);
        assertEq(vu, END);
        console2.logBytes(abi.encodeCall(Account222.addSession, (sess, _scope(300))));
    }

    function test_sessionDepositsWithinLimit() public {
        _bundle(_op(_sessNonce(0), _deposit(100), sessionKey));
        assertEq(_deposited(address(acct)), 100);
        (,,,, uint128 spent,,) = acct.sessions(sess);
        assertEq(spent, 100);
    }

    function test_sessionOverLimitRejected() public {
        _bundle(_op(_sessNonce(0), _deposit(200), sessionKey));
        _expectFail(_op(_sessNonce(1), _deposit(200), sessionKey), "AA24 signature error");
        assertEq(_deposited(address(acct)), 200);
    }

    function test_sessionOtherTargetRejected() public {
        bytes memory cd =
            abi.encodeCall(Account222.execute, (address(token), 0, abi.encodeCall(token.transfer, (sess, 100))));
        _expectFail(_op(_sessNonce(0), cd, sessionKey), "AA24 signature error");
        assertEq(token.balanceOf(address(acct)), 1000);
    }

    function test_sessionOtherSelectorRejected() public {
        bytes memory cd = abi.encodeCall(
            Account222.execute, (address(market), 0, abi.encodeCall(market.withdraw, (address(token), 100)))
        );
        _expectFail(_op(_sessNonce(0), cd, sessionKey), "AA24 signature error");
    }

    function test_sessionBatchRejected() public {
        address[] memory t = new address[](1);
        bytes[] memory d = new bytes[](1);
        t[0] = address(market);
        d[0] = abi.encodeCall(market.deposit, (address(token), 100));
        _expectFail(
            _op(_sessNonce(0), abi.encodeCall(Account222.executeBatch, (t, d)), sessionKey), "AA24 signature error"
        );
    }

    function test_sessionCannotAddSession() public {
        bytes memory inner = abi.encodeCall(Account222.addSession, (sess, _scope(type(uint128).max)));
        bytes memory cd = abi.encodeCall(Account222.execute, (address(acct), 0, inner));
        _expectFail(_op(_sessNonce(0), cd, sessionKey), "AA24 signature error");
    }

    function test_sessionExpiredRejected() public {
        vm.warp(END + 1);
        _expectFail(_op(_sessNonce(0), _deposit(100), sessionKey), "AA22 expired or not due");
    }

    function test_sessionNotYetValidRejected() public {
        vm.warp(START - 1);
        _expectFail(_op(_sessNonce(0), _deposit(100), sessionKey), "AA22 expired or not due");
    }

    function test_revokedSessionRejected() public {
        bytes memory inner = abi.encodeCall(Account222.revokeSession, (sess));
        _bundle(
            _op(ep.getNonce(address(acct), 0), abi.encodeCall(Account222.execute, (address(acct), 0, inner)), ownerKey)
        );
        _expectFail(_op(_sessNonce(0), _deposit(100), sessionKey), "AA24 signature error");
    }

    // セッションキーは自分のアドレスをkeyにしたナンスの列だけ。持ち主の列(key 0)は別に数える
    function test_sessionNonceKeyIndependent() public {
        _expectFail(_op(ep.getNonce(address(acct), 0), _deposit(100), sessionKey), "AA24 signature error");
        _bundle(_op(_sessNonce(0), _deposit(100), sessionKey));
        assertEq(ep.getNonce(address(acct), uint192(uint160(sess))), _sessNonce(1));
        assertEq(ep.getNonce(address(acct), 0), 1);
        console2.log("session nonce key", uint256(uint160(sess)));
    }

    function test_ownerNotLimited() public {
        _bundle(_op(ep.getNonce(address(acct), 0), _deposit(1000), ownerKey));
        assertEq(_deposited(address(acct)), 1000);
    }

    // セッションを記録し直すと使った量が0から。範囲を狭めるには消して新しく記録する
    function test_reAddSessionResetsSpent() public {
        _bundle(_op(_sessNonce(0), _deposit(200), sessionKey));
        _addSession(300);
        _bundle(_op(_sessNonce(1), _deposit(300), sessionKey));
        assertEq(_deposited(address(acct)), 500);
        (,,,, uint128 spent,,) = acct.sessions(sess);
        assertEq(spent, 300);
    }
}
