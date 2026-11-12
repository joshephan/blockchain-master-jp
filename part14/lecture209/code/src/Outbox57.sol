// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Message, Msg} from "./Msg57.sol";

// 送る側のコントラクト(outbox)。メッセージを書いておきログを一行残すところで終わる。他のチェーンを呼ぶ行はない
contract ToyOutbox {
    event MessageSent(bytes32 indexed id, Message m);

    uint64 public nonce;
    mapping(bytes32 id => bool) public sent;

    function send(uint256 dstChainId, address receiver, bytes calldata payload) external returns (bytes32 id) {
        nonce++;
        Message memory m = Message(block.chainid, address(this), nonce, msg.sender, dstChainId, receiver, payload);
        id = Msg.idOf(m);
        sent[id] = true;
        emit MessageSent(id, m);
    }
}
