// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Message, Msg, IVerifier, IReceiver} from "./Msg57.sol";

// 受け取り側のコントラクト(endpoint)。誰が入れても(中継)検証の席が正しいと言わなければ受け取るアプリを呼ばない
contract ToyEndpoint {
    error WrongDestination(uint256 dstChainId);
    error UnknownSource(uint256 srcChainId, address srcOutbox);
    error NotVerified(bytes32 id);
    error AlreadyDelivered(bytes32 id);

    event Delivered(bytes32 indexed id);
    event DeliveryFailed(bytes32 indexed id, bytes reason);

    uint8 internal constant NONE = 0;
    uint8 internal constant DONE = 1;
    uint8 internal constant FAILED = 2;

    IVerifier public immutable verifier;
    mapping(uint256 chainId => address outbox) public outboxOf;
    mapping(bytes32 id => uint8) public status;

    // 信頼するoutboxはデプロイ時にチェーン番号とアドレスの組で決める。変える関数はない
    constructor(IVerifier verifier_, uint256[] memory srcChainIds, address[] memory srcOutboxes) {
        verifier = verifier_;
        for (uint256 i = 0; i < srcChainIds.length; i++) {
            outboxOf[srcChainIds[i]] = srcOutboxes[i];
        }
    }

    // 入れる人は誰でもよい。受け取るアプリが失敗したら記録だけ残し、入れ直せる
    function deliver(Message calldata m, bytes calldata proof) external {
        if (m.dstChainId != block.chainid) revert WrongDestination(m.dstChainId);
        if (m.srcOutbox == address(0) || outboxOf[m.srcChainId] != m.srcOutbox) {
            revert UnknownSource(m.srcChainId, m.srcOutbox);
        }
        bytes32 id = Msg.idOf(m);
        if (status[id] == DONE) revert AlreadyDelivered(id);
        if (!verifier.verify(id, proof)) revert NotVerified(id);
        try IReceiver(m.receiver).onMessage(m.srcChainId, m.sender, m.payload) {
            status[id] = DONE;
            emit Delivered(id);
        } catch (bytes memory reason) {
            status[id] = FAILED;
            emit DeliveryFailed(id, reason);
        }
    }
}
