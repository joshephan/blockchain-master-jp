// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {PackedUserOperation, IAccount, IPaymaster, PostOpMode} from "./UserOp.sol";

// 講義用のEntryPointのまね。実際のEntryPointのコードではない
// 原文から持ってきたもの: handleOpsの検証ループと実行ループ、192ビットのkeyと64ビットのsequenceのナンス、
// チェーン番号とEntryPointのアドレスが入るuserOpHash(EIP-712)、預け金(deposit)、ペイマスターの検証とpostOp、AAエラーの文言
// ないもの: initCodeでのアカウント作成、aggregator、ステーク、使わなかったガスのペナルティ、EIP-7702、シミュレーションのルール
contract EntryPoint219 {
    struct OpInfo {
        bytes32 userOpHash;
        address payer;
        address paymaster;
        uint256 prefund;
        uint256 validationGas;
        uint256 callGasLimit;
        uint256 postOpGasLimit;
        uint256 gasPrice;
        bytes context;
    }

    bytes32 private constant TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant PACKED_USEROP_TYPEHASH = keccak256(
        "PackedUserOperation(address sender,uint256 nonce,bytes initCode,bytes callData,bytes32 accountGasLimits,uint256 preVerificationGas,bytes32 gasFees,bytes paymasterAndData)"
    );

    mapping(address => uint256) public balanceOf; // 預け金
    mapping(address => mapping(uint192 => uint256)) public nonceSequenceNumber;

    error FailedOp(uint256 opIndex, string reason);

    event Deposited(address indexed account, uint256 totalDeposit);
    event Withdrawn(address indexed account, address withdrawAddress, uint256 amount);
    event UserOperationEvent(
        bytes32 indexed userOpHash,
        address indexed sender,
        address indexed paymaster,
        uint256 nonce,
        bool success,
        uint256 actualGasCost,
        uint256 actualGasUsed
    );
    event UserOperationRevertReason(bytes32 indexed userOpHash, address indexed sender, uint256 nonce, bytes revertReason);

    // ---- 預け金 ----
    receive() external payable {
        depositTo(msg.sender);
    }

    function depositTo(address account) public payable {
        balanceOf[account] += msg.value;
        emit Deposited(account, balanceOf[account]);
    }

    function withdrawTo(address payable withdrawAddress, uint256 amount) external {
        balanceOf[msg.sender] -= amount;
        (bool ok,) = withdrawAddress.call{value: amount}("");
        require(ok, "failed to withdraw");
        emit Withdrawn(msg.sender, withdrawAddress, amount);
    }

    // ---- ナンス: 上位192ビットのkey、下位64ビットのsequence ----
    function getNonce(address sender, uint192 key) external view returns (uint256) {
        return nonceSequenceNumber[sender][key] | (uint256(key) << 64);
    }

    // ---- userOpHash: signatureを除いた欄全部 + チェーン番号 + このEntryPointのアドレス ----
    function getUserOpHash(PackedUserOperation calldata op) public view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                PACKED_USEROP_TYPEHASH,
                op.sender,
                op.nonce,
                keccak256(op.initCode),
                keccak256(op.callData),
                op.accountGasLimits,
                op.preVerificationGas,
                op.gasFees,
                keccak256(op.paymasterAndData)
            )
        );
        bytes32 domain =
            keccak256(abi.encode(TYPE_HASH, keccak256("ERC4337"), keccak256("1"), block.chainid, address(this)));
        return keccak256(abi.encodePacked("\x19\x01", domain, structHash));
    }

    // ---- バンドル一つ: 検証ループ全部のあとに実行ループ ----
    function handleOps(PackedUserOperation[] calldata ops, address payable beneficiary) external {
        OpInfo[] memory infos = new OpInfo[](ops.length);
        for (uint256 i = 0; i < ops.length; i++) {
            infos[i] = _validate(i, ops[i]);
        }
        uint256 collected;
        for (uint256 i = 0; i < ops.length; i++) {
            collected += _execute(ops[i], infos[i]);
        }
        (bool ok,) = beneficiary.call{value: collected}("");
        if (!ok) revert FailedOp(0, "AA91 failed send to beneficiary");
    }

    function _validate(uint256 i, PackedUserOperation calldata op) internal returns (OpInfo memory info) {
        uint256 preGas = gasleft();
        info.userOpHash = getUserOpHash(op);

        uint192 key = uint192(op.nonce >> 64);
        uint64 seq = uint64(op.nonce);
        if (nonceSequenceNumber[op.sender][key]++ != seq) revert FailedOp(i, "AA25 invalid account nonce");
        if (op.initCode.length != 0) revert FailedOp(i, "initCode not in this mimic");
        if (op.sender.code.length == 0) revert FailedOp(i, "AA20 account not deployed");

        uint256 verificationGasLimit = uint128(bytes16(op.accountGasLimits));
        info.callGasLimit = uint128(uint256(op.accountGasLimits));
        uint256 maxPriorityFeePerGas = uint128(bytes16(op.gasFees));
        uint256 maxFeePerGas = uint128(uint256(op.gasFees));
        uint256 pmVerificationGasLimit;
        if (op.paymasterAndData.length >= 52) {
            info.paymaster = address(bytes20(op.paymasterAndData[0:20]));
            pmVerificationGasLimit = uint128(bytes16(op.paymasterAndData[20:36]));
            info.postOpGasLimit = uint128(bytes16(op.paymasterAndData[36:52]));
        }
        uint256 requiredGas = verificationGasLimit + info.callGasLimit + pmVerificationGasLimit
            + info.postOpGasLimit + op.preVerificationGas;
        info.prefund = requiredGas * maxFeePerGas;
        uint256 basePlusTip = maxPriorityFeePerGas + block.basefee;
        info.gasPrice = basePlusTip < maxFeePerGas ? basePlusTip : maxFeePerGas;

        // アカウントの検証: ペイマスターがいればアカウントにお金を求めない(missingAccountFunds 0)
        uint256 missing;
        if (info.paymaster == address(0) && balanceOf[op.sender] < info.prefund) {
            missing = info.prefund - balanceOf[op.sender];
        }
        uint256 accountData;
        try IAccount(op.sender).validateUserOp{gas: verificationGasLimit}(op, info.userOpHash, missing) returns (
            uint256 vd
        ) {
            accountData = vd;
        } catch {
            revert FailedOp(i, "AA23 reverted");
        }
        _checkData(i, accountData, "AA24 signature error", "AA22 expired or not due");

        if (info.paymaster == address(0)) {
            if (balanceOf[op.sender] < info.prefund) revert FailedOp(i, "AA21 didn't pay prefund");
            balanceOf[op.sender] -= info.prefund;
            info.payer = op.sender;
        } else {
            if (balanceOf[info.paymaster] < info.prefund) revert FailedOp(i, "AA31 paymaster deposit too low");
            balanceOf[info.paymaster] -= info.prefund;
            info.payer = info.paymaster;
            try IPaymaster(info.paymaster).validatePaymasterUserOp{gas: pmVerificationGasLimit}(
                op, info.userOpHash, info.prefund
            ) returns (bytes memory context, uint256 pmData) {
                info.context = context;
                _checkData(i, pmData, "AA34 signature error", "AA32 paymaster expired or not due");
            } catch {
                revert FailedOp(i, "AA33 reverted");
            }
        }
        info.validationGas = preGas - gasleft();
    }

    // validationData: 下位20バイトが1なら署名失敗、validUntil 0は期限なし
    function _checkData(uint256 i, uint256 data, string memory sigReason, string memory timeReason) internal view {
        if (uint160(data) == 1) revert FailedOp(i, sigReason);
        uint48 validUntil = uint48(data >> 160);
        uint48 validAfter = uint48(data >> 208);
        if (validUntil == 0) validUntil = type(uint48).max;
        if (block.timestamp > validUntil || block.timestamp < validAfter) revert FailedOp(i, timeReason);
    }

    function _execute(PackedUserOperation calldata op, OpInfo memory info) internal returns (uint256 actualGasCost) {
        uint256 preGas = gasleft();
        (bool success, bytes memory ret) = op.sender.call{gas: info.callGasLimit}(op.callData);
        if (!success) emit UserOperationRevertReason(info.userOpHash, op.sender, op.nonce, ret);

        uint256 actualGas = info.validationGas + (preGas - gasleft()) + op.preVerificationGas;
        if (info.context.length > 0) {
            PostOpMode mode = success ? PostOpMode.opSucceeded : PostOpMode.opReverted;
            try IPaymaster(info.paymaster).postOp{gas: info.postOpGasLimit}(
                mode, info.context, actualGas * info.gasPrice, info.gasPrice
            ) {} catch {
                revert FailedOp(0, "AA50 postOp reverted");
            }
            actualGas = info.validationGas + (preGas - gasleft()) + op.preVerificationGas;
        }
        actualGasCost = actualGas * info.gasPrice;
        if (actualGasCost > info.prefund) actualGasCost = info.prefund; // まね: 先に確保したお金まで
        balanceOf[info.payer] += info.prefund - actualGasCost; // 残ったお金は払った側の預け金に戻す
        emit UserOperationEvent(info.userOpHash, op.sender, info.paymaster, op.nonce, success, actualGasCost, actualGas);
    }
}
