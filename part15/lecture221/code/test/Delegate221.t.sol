// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Vm} from "forge-std/Vm.sol";
import {console2} from "forge-std/console2.sol";
import {Base} from "./Base.sol";
import {Delegate221} from "../src/Delegate221.sol";
import {EntryPoint219} from "../src/EntryPoint219.sol";
import {PackedUserOperation} from "../src/UserOp.sol";

contract Delegate221Test is Base {
    EntryPoint219 internal ep;
    Delegate221 internal d1;
    Delegate221 internal d2;
    uint256 internal aliceKey = 0xA11CE;
    address payable internal alice;
    address internal sponsor = makeAddr("sponsor");
    address internal stranger = makeAddr("stranger");

    function setUp() public {
        _setUpMarket();
        ep = new EntryPoint219();
        d1 = new Delegate221(address(ep));
        d2 = new Delegate221(address(ep));
        alice = payable(vm.addr(aliceKey));
        token.transfer(alice, 500);
        vm.deal(sponsor, 1 ether);
    }

    function _delegate(address target) internal {
        vm.signAndAttachDelegation(target, aliceKey);
        vm.prank(sponsor);
        (bool ok,) = alice.call(""); // 委任を載せていくトランザクション一つ
        require(ok, "delegation tx");
    }

    function _depositCalls(uint256 amount) internal view returns (Delegate221.Call[] memory calls) {
        calls = new Delegate221.Call[](2);
        calls[0] = Delegate221.Call(address(token), 0, abi.encodeCall(token.approve, (address(market), amount)));
        calls[1] = Delegate221.Call(address(market), 0, abi.encodeCall(market.deposit, (address(token), amount)));
    }

    function _sig(uint256 chainId, address self, uint256 n, Delegate221.Call[] memory calls)
        internal
        view
        returns (bytes memory)
    {
        bytes32 digest = keccak256(abi.encode(chainId, address(alice), self, n, keccak256(abi.encode(calls))));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(aliceKey, digest);
        return abi.encodePacked(r, s, v);
    }

    // 委任の印: 0xef0100 + アドレス20バイト = 23バイト
    function test_delegationIndicator() public {
        assertEq(alice.code.length, 0);
        _delegate(address(d1));
        assertEq(alice.code, abi.encodePacked(hex"ef0100", address(d1)));
        assertEq(alice.code.length, 23);
        // EOAのナンスが上がることはanvilで確認(cast nonce)
        console2.logBytes(alice.code);
    }

    // 別のアカウントが送り、EOAの鍵は署名だけ。承認 + 預け入れを一度に、MarketはEOAのアドレス宛てに記録
    function test_sponsorRunsSignedBatch() public {
        Delegate221.Call[] memory calls = _depositCalls(100);
        bytes memory sig = _sig(block.chainid, address(d1), 0, calls);
        vm.signAndAttachDelegation(address(d1), aliceKey);
        vm.prank(sponsor);
        Delegate221(alice).executeSigned(calls, sig);
        assertEq(_deposited(alice), 100);
        assertEq(token.balanceOf(alice), 400);
        assertEq(alice.balance, 0);
        assertEq(Delegate221(alice).nonce(), 1);
    }

    // コンストラクタが書いた値は委任コードのアドレスにだけ。EOAのアドレスから読むと0
    function test_constructorStorageNotAtEOA() public {
        _delegate(address(d1));
        assertEq(d1.label(), 221);
        assertEq(Delegate221(alice).label(), 0);
        assertEq(Delegate221(alice).SELF(), address(d1)); // immutableはコードに埋め込まれているので一緒に読める
    }

    function test_strangerExecuteRejected() public {
        _delegate(address(d1));
        Delegate221.Call[] memory calls = new Delegate221.Call[](1);
        calls[0] = Delegate221.Call(address(token), 0, abi.encodeCall(token.transfer, (stranger, 500)));
        vm.prank(stranger);
        vm.expectRevert(Delegate221.NotSelf.selector);
        Delegate221(alice).execute(calls);
        assertEq(token.balanceOf(alice), 500);
    }

    function test_sameSigRejected() public {
        _delegate(address(d1));
        Delegate221.Call[] memory calls = _depositCalls(100);
        bytes memory sig = _sig(block.chainid, address(d1), 0, calls);
        vm.prank(sponsor);
        Delegate221(alice).executeSigned(calls, sig);
        vm.prank(sponsor);
        vm.expectRevert(Delegate221.BadSigner.selector);
        Delegate221(alice).executeSigned(calls, sig);
        assertEq(_deposited(alice), 100);
    }

    function test_otherChainSigRejected() public {
        _delegate(address(d1));
        Delegate221.Call[] memory calls = _depositCalls(100);
        bytes memory sig = _sig(1, address(d1), 0, calls);
        vm.prank(sponsor);
        vm.expectRevert(Delegate221.BadSigner.selector);
        Delegate221(alice).executeSigned(calls, sig);
    }

    // 同じEOA、同じ使用番号でも委任コードが違えばSELFが違い署名が合わない
    function test_sigForOtherDelegateRejected() public {
        _delegate(address(d2));
        Delegate221.Call[] memory calls = _depositCalls(100);
        bytes memory sig = _sig(block.chainid, address(d1), 0, calls);
        vm.prank(sponsor);
        vm.expectRevert(Delegate221.BadSigner.selector);
        Delegate221(alice).executeSigned(calls, sig);
    }

    // 委任を変えても消してもEOAのアドレスのストレージはそのまま
    function test_storageStaysAfterRedelegation() public {
        _delegate(address(d1));
        Delegate221.Call[] memory calls = _depositCalls(100);
        vm.prank(sponsor);
        Delegate221(alice).executeSigned(calls, _sig(block.chainid, address(d1), 0, calls));
        assertEq(Delegate221(alice).nonce(), 1);

        _delegate(address(d2));
        assertEq(alice.code, abi.encodePacked(hex"ef0100", address(d2)));
        assertEq(Delegate221(alice).nonce(), 1);

        _delegate(address(0));
        assertEq(alice.code.length, 0);
        assertEq(uint256(vm.load(alice, bytes32(uint256(1)))), 1);
    }

    // 委任したEOAがEntryPointのsenderに。署名はEOAの鍵がuserOpHashに
    function test_delegatedEoaInEntryPoint() public {
        _delegate(address(d1));
        vm.deal(alice, 1 ether);
        vm.fee(1 gwei);
        PackedUserOperation memory op;
        op.sender = alice;
        op.nonce = 0;
        op.callData = abi.encodeCall(Delegate221.execute, (_depositCalls(100)));
        op.accountGasLimits = bytes32((uint256(200_000) << 128) | 300_000);
        op.preVerificationGas = 50_000;
        op.gasFees = bytes32((uint256(1 gwei) << 128) | 3 gwei);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(aliceKey, ep.getUserOpHash(op));
        op.signature = abi.encodePacked(r, s, v);
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = op;
        vm.prank(sponsor, sponsor);
        ep.handleOps(ops, payable(sponsor));
        assertEq(_deposited(alice), 100);
        assertEq(ep.getNonce(alice, 0), 1);
        assertEq(Delegate221(alice).nonce(), 0); // EntryPointのナンスと委任コードのナンスは別
    }
}
