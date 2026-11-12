// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Script, console2} from "forge-std/Script.sol";
import {Market} from "../src/market/Market.sol";
import {IERC20, Rate, Ratio} from "../src/market/MarketTypes.sol";
import {StdToken} from "../src/market/StdToken.sol";
import {EntryPoint219} from "../src/EntryPoint219.sol";
import {Account219} from "../src/Account219.sol";
import {SponsorPaymaster220, TokenPaymaster220, ITokenLike} from "../src/Paymaster220.sol";
import {PackedUserOperation} from "../src/UserOp.sol";

// ローカルチェーンのデモ: アカウント0番がデプロイ、アカウント1番がバンドラー、持ち主の鍵は署名だけ(ETH 0)
contract Demo is Script {
    uint256 constant K0 = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    uint256 constant K1 = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
    uint256 constant KO = 0xA11CE;
    uint256 constant KS = 0x5B0; // 肩代わりする側の鍵

    EntryPoint219 ep;
    Account219 acct;
    Market market;
    StdToken token;

    function _op(uint256 nonce, bytes memory callData, bytes memory pm) internal view returns (PackedUserOperation memory op) {
        op.sender = address(acct);
        op.nonce = nonce;
        op.callData = callData;
        op.accountGasLimits = bytes32((uint256(200_000) << 128) | 300_000);
        op.preVerificationGas = 50_000;
        op.gasFees = bytes32((uint256(1 gwei) << 128) | 3 gwei);
        op.paymasterAndData = pm;
    }

    function _signed(PackedUserOperation memory op) internal view returns (PackedUserOperation memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(KO, ep.getUserOpHash(op));
        op.signature = abi.encodePacked(r, s, v);
        return op;
    }

    function _calls(address[] memory targets, bytes[] memory datas) internal pure returns (bytes memory) {
        return abi.encodeCall(Account219.executeBatch, (targets, datas));
    }

    function _send(PackedUserOperation memory op) internal {
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = op;
        vm.broadcast(K1);
        ep.handleOps(ops, payable(vm.addr(K1)));
    }

    function _setUp() internal {
        vm.startBroadcast(K0);
        ep = new EntryPoint219();
        token = new StdToken("Test", "TST", 18, 1_000_000 ether);
        market = new Market(vm.addr(K0), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        acct = new Account219(address(ep), vm.addr(KO));
        token.transfer(address(acct), 100 ether);
        vm.stopBroadcast();
        console2.log("EntryPoint219", address(ep));
        console2.log("Account219", address(acct));
        console2.log("Market", address(market));
        console2.log("StdToken", address(token));
        console2.log("owner", vm.addr(KO));
    }

    // 第219講: アカウントのアドレスにETH 1を入れ、承認 + 預け入れをUserOperation一つで
    function run219() external {
        _setUp();
        vm.broadcast(K0);
        payable(address(acct)).transfer(1 ether);
        address[] memory targets = new address[](2);
        bytes[] memory datas = new bytes[](2);
        targets[0] = address(token);
        datas[0] = abi.encodeCall(token.approve, (address(market), 100));
        targets[1] = address(market);
        datas[1] = abi.encodeCall(market.deposit, (address(token), 100));
        PackedUserOperation memory op = _signed(_op(0, _calls(targets, datas), ""));
        console2.log("userOpHash");
        console2.logBytes32(ep.getUserOpHash(op));
        _send(op);
    }

    // 第220講: アカウントのアドレスのETHは0。一つ目のUserOperationは肩代わり(承認二つ + 預け入れ)、二つ目はトークンで払う(預け入れ)
    function run220() external {
        _setUp();
        vm.startBroadcast(K0);
        SponsorPaymaster220 spm = new SponsorPaymaster220(address(ep), vm.addr(KS));
        spm.deposit{value: 1 ether}();
        TokenPaymaster220 tpm = new TokenPaymaster220(address(ep), ITokenLike(address(token)), 2000 ether);
        tpm.deposit{value: 1 ether}();
        vm.stopBroadcast();
        console2.log("SponsorPaymaster220", address(spm));
        console2.log("TokenPaymaster220", address(tpm));

        address[] memory targets = new address[](3);
        bytes[] memory datas = new bytes[](3);
        targets[0] = address(token);
        datas[0] = abi.encodeCall(token.approve, (address(tpm), type(uint256).max));
        targets[1] = address(token);
        datas[1] = abi.encodeCall(token.approve, (address(market), 1000));
        targets[2] = address(market);
        datas[2] = abi.encodeCall(market.deposit, (address(token), 100));
        PackedUserOperation memory op = _op(0, _calls(targets, datas), "");
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(KS, spm.getHash(op, 0, 0));
        op.paymasterAndData =
            abi.encodePacked(address(spm), uint128(100_000), uint128(0), uint48(0), uint48(0), abi.encodePacked(r, s, v));
        _send(_signed(op));

        address[] memory t2 = new address[](1);
        bytes[] memory d2 = new bytes[](1);
        t2[0] = address(market);
        d2[0] = abi.encodeCall(market.deposit, (address(token), 200));
        _send(_signed(_op(1, _calls(t2, d2), abi.encodePacked(address(tpm), uint128(100_000), uint128(100_000)))));
    }
}
