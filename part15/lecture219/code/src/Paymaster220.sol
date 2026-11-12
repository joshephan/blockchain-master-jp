// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {PackedUserOperation, IPaymaster, PostOpMode, ValidationData} from "./UserOp.sol";

interface IEntryPointDeposit {
    function depositTo(address account) external payable;
    function balanceOf(address account) external view returns (uint256);
}

interface ITokenLike {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
}

// 講義用の肩代わりペイマスター: 肩代わりする側(sponsor)の鍵が署名したUserOperationだけガスを代わりに払う
// paymasterData = validUntil 6バイト + validAfter 6バイト + 署名65バイト
contract SponsorPaymaster220 is IPaymaster {
    address public immutable entryPoint;
    address public immutable sponsor;

    error NotEntryPoint();

    constructor(address entryPoint_, address sponsor_) {
        entryPoint = entryPoint_;
        sponsor = sponsor_;
    }

    function deposit() external payable {
        IEntryPointDeposit(entryPoint).depositTo{value: msg.value}(address(this));
    }

    // 署名の材料: userOpHashにはこの署名が入ったpaymasterAndDataが含まれるので使えない。欄を直接集める
    function getHash(PackedUserOperation calldata op, uint48 validUntil, uint48 validAfter)
        public
        view
        returns (bytes32)
    {
        return keccak256(
            abi.encode(
                op.sender,
                op.nonce,
                keccak256(op.callData),
                op.accountGasLimits,
                op.preVerificationGas,
                op.gasFees,
                block.chainid,
                address(this),
                validUntil,
                validAfter
            )
        );
    }

    function validatePaymasterUserOp(PackedUserOperation calldata op, bytes32, uint256)
        external
        view
        returns (bytes memory context, uint256 validationData)
    {
        if (msg.sender != entryPoint) revert NotEntryPoint();
        bytes calldata data = op.paymasterAndData[52:];
        uint48 validUntil = uint48(bytes6(data[0:6]));
        uint48 validAfter = uint48(bytes6(data[6:12]));
        bytes calldata sig = data[12:];
        address signer = address(0);
        if (sig.length == 65) {
            signer = ecrecover(
                getHash(op, validUntil, validAfter), uint8(sig[64]), bytes32(sig[0:32]), bytes32(sig[32:64])
            );
        }
        bool failed = signer == address(0) || signer != sponsor;
        return ("", ValidationData.pack(failed, validUntil, validAfter)); // contextなし → postOpを呼ばない
    }

    function postOp(PostOpMode, bytes calldata, uint256, uint256) external view {
        if (msg.sender != entryPoint) revert NotEntryPoint();
    }
}

// 講義用のトークンペイマスター: ガスはこのペイマスターがETHで払い、アカウントからトークンを受け取る
// 検証で最大コスト分のトークンを先に受け取り、postOpで実際のコストとの差を返す
contract TokenPaymaster220 is IPaymaster {
    address public immutable entryPoint;
    ITokenLike public immutable token;
    uint256 public immutable tokensPerEth; // 1 ETHあたりのトークン量(デプロイ時に決めた固定値、相場ではない)

    error NotEntryPoint();

    constructor(address entryPoint_, ITokenLike token_, uint256 tokensPerEth_) {
        entryPoint = entryPoint_;
        token = token_;
        tokensPerEth = tokensPerEth_;
    }

    function deposit() external payable {
        IEntryPointDeposit(entryPoint).depositTo{value: msg.value}(address(this));
    }

    function toTokens(uint256 weiAmount) public view returns (uint256) {
        return weiAmount * tokensPerEth / 1 ether;
    }

    function validatePaymasterUserOp(PackedUserOperation calldata op, bytes32, uint256 maxCost)
        external
        returns (bytes memory context, uint256 validationData)
    {
        if (msg.sender != entryPoint) revert NotEntryPoint();
        uint256 maxTokens = toTokens(maxCost);
        require(token.transferFrom(op.sender, address(this), maxTokens), "token prefund");
        return (abi.encode(op.sender, maxTokens), 0);
    }

    function postOp(PostOpMode, bytes calldata context, uint256 actualGasCost, uint256) external {
        if (msg.sender != entryPoint) revert NotEntryPoint();
        (address sender, uint256 maxTokens) = abi.decode(context, (address, uint256));
        uint256 used = toTokens(actualGasCost);
        if (used < maxTokens) require(token.transfer(sender, maxTokens - used), "token refund");
    }
}
