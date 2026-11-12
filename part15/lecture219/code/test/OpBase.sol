// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Vm} from "forge-std/Vm.sol";
import {Base} from "./Base.sol";
import {EntryPoint219} from "../src/EntryPoint219.sol";
import {Account219} from "../src/Account219.sol";
import {PackedUserOperation} from "../src/UserOp.sol";

// UserOperationを作って署名し、バンドルで出す土台(バンドラーの役はテスト内のアカウントbundler)
abstract contract OpBase is Base {
    EntryPoint219 internal ep;
    Account219 internal acct;
    uint256 internal ownerKey = 0xA11CE;
    address internal owner;
    address internal bundler = makeAddr("bundler");
    address payable internal beneficiary = payable(makeAddr("beneficiary"));

    uint128 internal constant VERIFICATION_GAS = 200_000;
    uint128 internal constant CALL_GAS = 300_000;
    uint256 internal constant PRE_VERIFICATION_GAS = 50_000;
    uint128 internal constant TIP = 1 gwei;
    uint128 internal constant MAX_FEE = 3 gwei;

    function _setUpAA() internal {
        _setUpMarket();
        vm.fee(1 gwei); // basefee
        ep = new EntryPoint219();
        owner = vm.addr(ownerKey);
        acct = new Account219(address(ep), owner);
        token.transfer(address(acct), 500);
        vm.deal(bundler, 1 ether);
    }

    function _op(uint256 nonce, bytes memory callData, bytes memory pmAndData)
        internal
        view
        returns (PackedUserOperation memory op)
    {
        op.sender = address(acct);
        op.nonce = nonce;
        op.callData = callData;
        op.accountGasLimits = bytes32((uint256(VERIFICATION_GAS) << 128) | CALL_GAS);
        op.preVerificationGas = PRE_VERIFICATION_GAS;
        op.gasFees = bytes32((uint256(TIP) << 128) | MAX_FEE);
        op.paymasterAndData = pmAndData;
    }

    function _sign(PackedUserOperation memory op, uint256 key) internal view returns (PackedUserOperation memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(key, ep.getUserOpHash(op));
        op.signature = abi.encodePacked(r, s, v);
        return op;
    }

    function _depositCall(uint256 amount) internal view returns (bytes memory) {
        address[] memory targets = new address[](2);
        bytes[] memory datas = new bytes[](2);
        targets[0] = address(token);
        datas[0] = abi.encodeCall(token.approve, (address(market), amount));
        targets[1] = address(market);
        datas[1] = abi.encodeCall(market.deposit, (address(token), amount));
        return abi.encodeCall(Account219.executeBatch, (targets, datas));
    }

    function _bundle(PackedUserOperation memory op) internal {
        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = op;
        vm.prank(bundler, bundler);
        ep.handleOps(ops, beneficiary);
    }

    // UserOperationEventのsuccess、actualGasCost、actualGasUsed
    function _lastOpEvent() internal view returns (bool success, uint256 cost, uint256 used) {
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 topic = EntryPoint219.UserOperationEvent.selector;
        for (uint256 i = logs.length; i > 0; i--) {
            if (logs[i - 1].topics[0] == topic) {
                (, success, cost, used) = abi.decode(logs[i - 1].data, (uint256, bool, uint256, uint256));
                return (success, cost, used);
            }
        }
        revert("no UserOperationEvent");
    }
}
