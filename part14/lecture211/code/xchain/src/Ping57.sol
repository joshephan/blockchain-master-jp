// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {IReceiver} from "./Msg57.sol";
import {ToyOutbox} from "./Outbox57.sol";

// 送るアプリ: 文を一行、他のチェーンへ送る。outboxに書いて終わり
contract PingSender {
    ToyOutbox public immutable outbox;

    constructor(ToyOutbox outbox_) {
        outbox = outbox_;
    }

    function ping(uint256 dstChainId, address receiver, string calldata text) external returns (bytes32) {
        return outbox.send(dstChainId, receiver, abi.encode(text));
    }
}

// 受け取るアプリ: endpointだけ、そして決めておいた(チェーン番号、アドレス)の組が送ったものだけを受け取る
contract PingApp is IReceiver {
    error NotEndpoint(address caller);
    error NotPeer(uint256 srcChainId, address sender);
    error EmptyText();

    address public immutable endpoint;
    uint256 public immutable peerChainId;
    address public immutable peer;
    uint256 public count;
    string public last;

    constructor(address endpoint_, uint256 peerChainId_, address peer_) {
        endpoint = endpoint_;
        peerChainId = peerChainId_;
        peer = peer_;
    }

    function onMessage(uint256 srcChainId, address sender, bytes calldata payload) external {
        if (msg.sender != endpoint) revert NotEndpoint(msg.sender);
        if (srcChainId != peerChainId || sender != peer) revert NotPeer(srcChainId, sender);
        string memory text = abi.decode(payload, (string));
        if (bytes(text).length == 0) revert EmptyText();
        count++;
        last = text;
    }
}
