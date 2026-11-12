// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ToyL2} from "./ToyL2.sol";

/// 講義用のL1の記録箱: シーケンサーのバッチと強制取り込みのキュー
/// L2ノードはlogに書かれた順番どおりに再実行して状態を作る
contract Inbox233 {
    struct Queued {
        bytes data;
        uint64 time;
    }

    uint256 public constant DELAY = 1 days; // 講義用の強制取り込みの待ち時間

    address public immutable sequencer;
    address[4] public owners; // L2の欄の番号のL1での持ち主

    bytes[] internal entries; // 決まった順番
    Queued[] internal queue;
    uint256 public qHead;

    event Enqueued(uint256 indexed index, address indexed sender, bytes data);
    event Appended(uint256 indexed entry, address indexed by, bool forced);

    error NotSequencer(address caller);
    error NotOwner(address caller);
    error TooMany(uint256 asked, uint256 waiting);
    error NothingDue(uint256 nextDueAt);

    constructor(address sequencer_, address[4] memory owners_) {
        sequencer = sequencer_;
        owners = owners_;
    }

    /// シーケンサーを通さずL1に直接入れる取引(送る欄 = 呼んだアドレスの欄)
    function enqueue(uint8 to, uint64 amount) external returns (uint256 index) {
        uint8 from = 255;
        for (uint8 i; i < 4; ++i) {
            if (owners[i] == msg.sender) from = i;
        }
        if (from == 255) revert NotOwner(msg.sender);
        bytes memory data = ToyL2.encodeTx(from, to, amount);
        index = queue.length;
        queue.push(Queued(data, uint64(block.timestamp)));
        emit Enqueued(index, msg.sender, data);
    }

    /// シーケンサーのバッチ。キューの先頭からtake個を先に入れ、そのあとにバッチをつなげる
    function appendBatch(bytes calldata batch, uint256 take) external {
        if (msg.sender != sequencer) revert NotSequencer(msg.sender);
        uint256 waiting = queue.length - qHead;
        if (take > waiting) revert TooMany(take, waiting);
        for (uint256 i; i < take; ++i) {
            _push(queue[qHead++].data, false);
        }
        if (batch.length > 0) _push(batch, false);
    }

    /// 待ち時間が過ぎたキューの取引を誰でも順番に入れる
    function forceInclude() external returns (uint256 moved) {
        while (qHead < queue.length && queue[qHead].time + DELAY <= block.timestamp) {
            _push(queue[qHead++].data, true);
            ++moved;
        }
        if (moved == 0) {
            uint256 due = qHead < queue.length ? queue[qHead].time + DELAY : 0;
            revert NothingDue(due);
        }
    }

    function _push(bytes memory data, bool forced) internal {
        entries.push(data);
        emit Appended(entries.length - 1, msg.sender, forced);
    }

    function entryCount() external view returns (uint256) {
        return entries.length;
    }

    function entry(uint256 i) external view returns (bytes memory) {
        return entries[i];
    }

    function waitingCount() external view returns (uint256) {
        return queue.length - qHead;
    }
}
