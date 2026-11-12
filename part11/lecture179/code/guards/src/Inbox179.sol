// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

// 別のチェーンから来た引き出し一覧を受け取る側。バリデーターthreshold人が署名したルートだけを受け付け、ルートの下の証明で一件ずつ処理
// 実際のトークンなし。処理した金額はreleasedに記録するだけ
contract ToyInbox {
    error BelowThreshold(uint256 signers);
    error NotValidator(address signer);
    error SignersNotSorted(address signer);
    error UnknownRoot(bytes32 root);
    error BadProof();
    error AlreadyProcessed(bytes32 leaf);

    uint256 public immutable threshold;
    mapping(address who => bool) public isValidator;
    mapping(bytes32 root => bool) public acceptedRoot;
    mapping(bytes32 leaf => bool) public processed;
    mapping(address to => uint256) public released;

    // バリデーターの集合はデプロイ時に決め、変える関数なし
    constructor(address[] memory validators, uint256 threshold_) {
        for (uint256 i = 0; i < validators.length; i++) {
            isValidator[validators[i]] = true;
        }
        threshold = threshold_;
    }

    // 署名する値にチェーン番号とこのコントラクトのアドレスを一緒に入れる
    function rootDigest(bytes32 root) public view returns (bytes32) {
        return MessageHashUtils.toEthSignedMessageHash(keccak256(abi.encode(block.chainid, address(this), root)));
    }

    // 署名は署名者のアドレスの昇順。同じ署名者を二回数えない
    function acceptRoot(bytes32 root, bytes[] calldata sigs) external {
        if (sigs.length < threshold) revert BelowThreshold(sigs.length);
        bytes32 digest = rootDigest(root);
        address last = address(0);
        for (uint256 i = 0; i < sigs.length; i++) {
            address signer = ECDSA.recover(digest, sigs[i]);
            if (!isValidator[signer]) revert NotValidator(signer);
            if (signer <= last) revert SignersNotSorted(signer);
            last = signer;
        }
        acceptedRoot[root] = true;
    }

    function leafOf(address to, uint256 amount, uint256 nonce) public view returns (bytes32) {
        return keccak256(bytes.concat(keccak256(abi.encode(block.chainid, address(this), to, amount, nonce))));
    }

    function release(address to, uint256 amount, uint256 nonce, bytes32 root, bytes32[] calldata proof) external {
        if (!acceptedRoot[root]) revert UnknownRoot(root);
        bytes32 leaf = leafOf(to, amount, nonce);
        if (!MerkleProof.verifyCalldata(proof, root, leaf)) revert BadProof();
        if (processed[leaf]) revert AlreadyProcessed(leaf);
        processed[leaf] = true;
        released[to] += amount;
    }
}
