// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Script, console2} from "forge-std/Script.sol";
import {Market} from "../src/market/Market.sol";
import {IERC20, Rate, Ratio} from "../src/market/MarketTypes.sol";
import {StdToken} from "../src/market/StdToken.sol";
import {EntryPoint219} from "../src/EntryPoint219.sol";
import {Account222} from "../src/Account222.sol";
import {PackedUserOperation} from "../src/UserOp.sol";

// 第222講のローカルチェーンのデモ: アカウント0番がデプロイ、アカウント1番がバンドラー、持ち主の鍵・セッションキーは署名だけ
contract Demo222 is Script {
    uint256 constant K0 = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 constant K1 = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
    uint256 constant KO = 0xA11CE;
    uint256 constant KS = 0x5E55; // セッションキー

    // デプロイの順番が決まっているのでアドレスが同じ(アカウント0番のナンス0・1・2・4)
    EntryPoint219 ep = EntryPoint219(payable(0x5FbDB2315678afecb367f032d93F642f64180aa3));
    StdToken token = StdToken(0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512);
    Market market = Market(0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0);
    Account222 acct = Account222(payable(0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9));

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

    function _send(PackedUserOperation memory op) internal {
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = op;
        vm.broadcast(K1);
        ep.handleOps(ops, payable(vm.addr(K1)));
    }

    function _sessNonce(uint64 seq) internal pure returns (uint256) {
        return (uint256(uint160(vm.addr(KS))) << 64) | seq;
    }

    function _deposit(uint256 amount) internal view returns (bytes memory) {
        return abi.encodeCall(
            Account222.execute, (address(market), 0, abi.encodeCall(market.deposit, (address(token), amount)))
        );
    }

    // デプロイ、持ち主のUserOperation(承認 + セッションの記録)、セッションのUserOperation(預け入れ100)
    function runA() external {
        vm.startBroadcast(K0);
        new EntryPoint219();
        new StdToken("Test", "TST", 18, 1_000_000);
        Market m = new Market(vm.addr(K0), Rate.wrap(5e16), Ratio.wrap(80));
        m.addAsset(IERC20(address(token)), Ratio.wrap(75));
        new Account222(address(ep), vm.addr(KO));
        token.transfer(address(acct), 1000);
        payable(address(acct)).transfer(1 ether);
        vm.stopBroadcast();

        Account222.Session memory s;
        s.target = address(market);
        s.selector = market.deposit.selector;
        s.asset = address(token);
        s.limit = 300;
        s.validAfter = uint48(block.timestamp);
        s.validUntil = uint48(block.timestamp + 1 hours);
        bytes memory grant = abi.encodeCall(Account222.addSession, (vm.addr(KS), s));
        address[] memory t = new address[](2);
        bytes[] memory d = new bytes[](2);
        t[0] = address(token);
        d[0] = abi.encodeCall(token.approve, (address(market), 300));
        t[1] = address(acct);
        d[1] = grant;
        console2.log("session key", vm.addr(KS));
        console2.log("grant calldata");
        console2.logBytes(grant);
        console2.log("validUntil", s.validUntil);
        _send(_op(0, abi.encodeCall(Account222.executeBatch, (t, d)), KO));
        _send(_op(_sessNonce(0), _deposit(100), KS));
    }

    // 1時間後に同じセッションキーで預け入れ50
    function runB() external {
        _send(_op(_sessNonce(1), _deposit(50), KS));
    }

    // セッションキーでトークンを送る
    function runC() external {
        bytes memory cd =
            abi.encodeCall(Account222.execute, (address(token), 0, abi.encodeCall(token.transfer, (vm.addr(KS), 100))));
        _send(_op(_sessNonce(1), cd, KS));
    }
}
