// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 講義用の最小のコントラクトアカウント二つ。持ち主は署名だけして、トランザクションは別のアカウント(代わりに払う側)が送る

// 署名の材料がやること三つだけの版
contract LooseWallet218 {
    address public immutable owner;

    error BadSigner();
    error CallFailed();

    constructor(address owner_) {
        owner = owner_;
    }

    receive() external payable {}

    // 誰でも呼べる。署名が正しければその仕事をする
    function execute(address target, uint256 value, bytes calldata data, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 digest = keccak256(abi.encode(target, value, data));
        if (ecrecover(digest, v, r, s) != owner) revert BadSigner();
        (bool ok,) = target.call{value: value}(data);
        if (!ok) revert CallFailed();
    }
}

// 署名の材料にチェーン番号、このアカウントのアドレス、使用番号を足した版
contract Wallet218 {
    address public immutable owner;
    uint256 public nonce;

    error BadSigner();
    error BadNonce(uint256 expected, uint256 got);
    error CallFailed();

    constructor(address owner_) {
        owner = owner_;
    }

    receive() external payable {}

    function digestOf(uint256 n, address target, uint256 value, bytes calldata data) public view returns (bytes32) {
        return keccak256(abi.encode(block.chainid, address(this), n, target, value, data));
    }

    function execute(
        uint256 n,
        address target,
        uint256 value,
        bytes calldata data,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (n != nonce) revert BadNonce(nonce, n);
        address signer = ecrecover(digestOf(n, target, value, data), v, r, s);
        if (signer == address(0) || signer != owner) revert BadSigner();
        nonce = n + 1;
        (bool ok,) = target.call{value: value}(data);
        if (!ok) revert CallFailed();
    }

    // 複数の呼び出しを一つの署名でまとめる。材料は配列三つ全体
    function executeBatch(
        uint256 n,
        address[] calldata targets,
        bytes[] calldata datas,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        if (n != nonce) revert BadNonce(nonce, n);
        bytes32 digest = keccak256(abi.encode(block.chainid, address(this), n, targets, datas));
        address signer = ecrecover(digest, v, r, s);
        if (signer == address(0) || signer != owner) revert BadSigner();
        nonce = n + 1;
        for (uint256 i = 0; i < targets.length; i++) {
            (bool ok,) = targets[i].call(datas[i]);
            if (!ok) revert CallFailed();
        }
    }
}
