// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// ERC-4337原文のPackedUserOperationの欄の名前そのまま
struct PackedUserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    bytes32 accountGasLimits; // verificationGasLimit 16バイト + callGasLimit 16バイト
    uint256 preVerificationGas;
    bytes32 gasFees; // maxPriorityFeePerGas 16バイト + maxFeePerGas 16バイト
    bytes paymasterAndData; // ペイマスターのアドレス20 + 検証ガス16 + postOpガス16 + paymasterData
    bytes signature;
}

// 原文のIAccountそのまま
interface IAccount {
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        returns (uint256 validationData);
}

enum PostOpMode {
    opSucceeded,
    opReverted
}

// 原文のペイマスターの関数二つそのまま
interface IPaymaster {
    function validatePaymasterUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 maxCost)
        external
        returns (bytes memory context, uint256 validationData);

    function postOp(PostOpMode mode, bytes calldata context, uint256 actualGasCost, uint256 actualUserOpFeePerGas)
        external;
}

// validationData一つの欄: 下位20バイトが結果(0は通過、1は署名失敗)、その上6バイトがvalidUntil、最上位6バイトがvalidAfter
library ValidationData {
    uint256 internal constant SIG_VALIDATION_FAILED = 1;

    function pack(bool sigFailed, uint48 validUntil, uint48 validAfter) internal pure returns (uint256) {
        return (sigFailed ? 1 : 0) | (uint256(validUntil) << 160) | (uint256(validAfter) << 208);
    }
}
