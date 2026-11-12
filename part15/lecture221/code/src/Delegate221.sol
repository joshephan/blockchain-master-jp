// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {PackedUserOperation, IAccount, ValidationData} from "./UserOp.sol";

// 講義用のEIP-7702の委任コード。EOAがこのアドレスを指すと、このコードがEOAのアドレスで動く
// 持ち主の欄なし: コードが動くアドレス(EOA)の鍵がそのまま持ち主
contract Delegate221 is IAccount {
    struct Call {
        address target;
        uint256 value;
        bytes data;
    }

    address public immutable SELF; // このコードがデプロイされたアドレス。ランタイムコードに埋め込まれる
    address public immutable entryPoint;
    uint256 public label = 221; // コンストラクタが書く値。デプロイ先アドレスのストレージにだけ残る
    uint256 public nonce; // 署名の使用番号。EOAのアドレスのストレージに積まれる

    error NotSelf();
    error BadSigner();
    error NotEntryPoint();
    error CallFailed(uint256 index, bytes reason);

    constructor(address entryPoint_) {
        SELF = address(this);
        entryPoint = entryPoint_;
    }

    receive() external payable {}

    // EOAの鍵で自分のアドレスに送ったトランザクション、またはEntryPointだけ
    function execute(Call[] calldata calls) external payable {
        if (msg.sender != address(this) && msg.sender != entryPoint) revert NotSelf();
        _run(calls);
    }

    // 別のアカウントが送るトランザクション: EOAの鍵の署名を確認
    function executeSigned(Call[] calldata calls, bytes calldata sig) external payable {
        address signer = _recover(digestOf(calls, nonce), sig);
        if (signer == address(0) || signer != address(this)) revert BadSigner();
        nonce++;
        _run(calls);
    }

    // 材料: チェーン番号、EOAのアドレス、このコードのアドレス、使用番号、呼び出しリスト
    function digestOf(Call[] calldata calls, uint256 n) public view returns (bytes32) {
        return keccak256(abi.encode(block.chainid, address(this), SELF, n, keccak256(abi.encode(calls))));
    }

    // ERC-4337アカウントの席。署名者はEOAの鍵
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        returns (uint256 validationData)
    {
        if (msg.sender != entryPoint) revert NotEntryPoint();
        address signer = _recover(userOpHash, userOp.signature);
        validationData = ValidationData.pack(signer == address(0) || signer != address(this), 0, 0);
        if (missingAccountFunds > 0) {
            (bool ok,) = payable(msg.sender).call{value: missingAccountFunds}("");
            ok;
        }
    }

    function _run(Call[] calldata calls) internal {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool ok, bytes memory ret) = calls[i].target.call{value: calls[i].value}(calls[i].data);
            if (!ok) revert CallFailed(i, ret);
        }
    }

    function _recover(bytes32 digest, bytes calldata sig) internal pure returns (address) {
        if (sig.length != 65) return address(0);
        return ecrecover(digest, uint8(sig[64]), bytes32(sig[0:32]), bytes32(sig[32:64]));
    }
}
