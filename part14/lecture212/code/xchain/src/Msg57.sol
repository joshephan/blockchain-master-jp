// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// クロスチェーンメッセージ一件。出発チェーン・送ったoutbox・連番・送ったアプリ・到着チェーン・受け取るアプリ・内容を全部含む
struct Message {
    uint256 srcChainId;
    address srcOutbox;
    uint64 nonce;
    address sender;
    uint256 dstChainId;
    address receiver;
    bytes payload;
}

library Msg {
    // メッセージ番号: 七つの欄全部をハッシュ。抜けた欄は入れ替えても同じ番号
    function idOf(Message memory m) internal pure returns (bytes32) {
        return keccak256(abi.encode(m));
    }
}

// 受け取り側の検証の席。モデルごとにこの関数一つだけが違う
interface IVerifier {
    function verify(bytes32 id, bytes calldata proof) external view returns (bool);
}

// 受け取るアプリが実装する関数
interface IReceiver {
    function onMessage(uint256 srcChainId, address sender, bytes calldata payload) external;
}
