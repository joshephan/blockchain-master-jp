// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ToyL2} from "./ToyL2.sol";

/// 講義用のオプティミスティックロールアップ: ステートルートの提出、異議申し立てのウィンドウ、再実行による判定
/// 一度に待つ提案は一つだけ。実際の設計の分割した争い(二分探索)は省いた
contract OptimisticRollup232 {
    struct Proposal {
        bytes32 prevRoot;
        bytes32 batchHash;
        bytes32 newRoot;
        uint64 proposedAt;
        address proposer;
    }

    uint256 public constant WINDOW = 1 hours; // 講義用に短くしたウィンドウ
    uint256 public constant BOND = 1 ether;

    bytes32 public finalizedRoot;
    Proposal public pending;
    bool public hasPending;

    event Proposed(address indexed proposer, bytes32 batchHash, bytes32 newRoot, bytes batch);
    event Challenged(address indexed challenger, bytes32 badRoot, bytes32 rightRoot);
    event Finalized(bytes32 newRoot);

    error BondRequired(uint256 sent);
    error StillPending();
    error NothingPending();
    error WindowOpen(uint256 endsAt);
    error WindowClosed(uint256 endedAt);
    error BadBatch();
    error BadPreState();
    error RootMatches();
    error PayFailed();

    constructor(uint256[4] memory genesis) {
        finalizedRoot = ToyL2.root(genesis);
    }

    /// バッチのデータと新しいルートを上げる。バッチはこの取引のcalldataとして公開される
    function propose(bytes calldata batch, bytes32 newRoot) external payable {
        if (msg.value != BOND) revert BondRequired(msg.value);
        if (hasPending) revert StillPending();
        pending = Proposal(finalizedRoot, keccak256(batch), newRoot, uint64(block.timestamp), msg.sender);
        hasPending = true;
        emit Proposed(msg.sender, keccak256(batch), newRoot, batch);
    }

    /// その前の状態と同じバッチを受け取ってチェーンの上で再実行。結果のルートが違えば提案を消す
    function challenge(uint256[4] calldata pre, bytes calldata batch) external {
        if (!hasPending) revert NothingPending();
        Proposal memory p = pending;
        uint256 end = p.proposedAt + WINDOW;
        if (block.timestamp >= end) revert WindowClosed(end);
        if (keccak256(batch) != p.batchHash) revert BadBatch();
        if (ToyL2.root(pre) != p.prevRoot) revert BadPreState();
        bytes32 right = ToyL2.root(ToyL2.run(pre, batch));
        if (right == p.newRoot) revert RootMatches();
        hasPending = false;
        delete pending;
        emit Challenged(msg.sender, p.newRoot, right);
        (bool ok,) = msg.sender.call{value: BOND}("");
        if (!ok) revert PayFailed();
    }

    /// ウィンドウが過ぎるまで異議がなければ確定
    function finalize() external {
        if (!hasPending) revert NothingPending();
        Proposal memory p = pending;
        uint256 end = p.proposedAt + WINDOW;
        if (block.timestamp < end) revert WindowOpen(end);
        finalizedRoot = p.newRoot;
        hasPending = false;
        delete pending;
        emit Finalized(p.newRoot);
        (bool ok,) = p.proposer.call{value: BOND}("");
        if (!ok) revert PayFailed();
    }
}
