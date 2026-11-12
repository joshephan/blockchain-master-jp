// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// 講義用の小さなL2: アカウント四つの残高と送金の取引だけがある
/// 取引一つ = 10バイト(送る欄1、受け取る欄1、金額8)。署名の確認は省いた
library ToyL2 {
    uint256 internal constant N = 4;
    uint256 internal constant TX_BYTES = 10;

    error BadLength(uint256 length);

    /// 取引一つを10バイトにまとめる
    function encodeTx(uint8 from, uint8 to, uint64 amount) internal pure returns (bytes memory) {
        return abi.encodePacked(from, to, amount);
    }

    /// バッチを順番に実行。残高が足りないか欄の番号が間違った取引は効果なしで通り過ぎる
    function run(uint256[4] memory bal, bytes memory batch) internal pure returns (uint256[4] memory) {
        if (batch.length % TX_BYTES != 0) revert BadLength(batch.length);
        for (uint256 i; i < batch.length; i += TX_BYTES) {
            uint8 f = uint8(batch[i]);
            uint8 t = uint8(batch[i + 1]);
            uint64 a;
            for (uint256 j; j < 8; ++j) {
                a = (a << 8) | uint64(uint8(batch[i + 2 + j]));
            }
            if (f >= N || t >= N || bal[f] < a) continue;
            bal[f] -= a;
            bal[t] += a;
        }
        return bal;
    }

    /// リーフ一つ = (欄の番号、残高)のハッシュ
    function leaf(uint256 i, uint256 b) internal pure returns (bytes32) {
        return keccak256(abi.encode(i, b));
    }

    /// リーフ四つで作ったステートルート
    function root(uint256[4] memory bal) internal pure returns (bytes32) {
        bytes32 l = keccak256(abi.encode(leaf(0, bal[0]), leaf(1, bal[1])));
        bytes32 r = keccak256(abi.encode(leaf(2, bal[2]), leaf(3, bal[3])));
        return keccak256(abi.encode(l, r));
    }

    /// 欄一つの残高がルートの下にあるか確認(証明 = 隣のリーフ、隣のブランチ)
    function verify(bytes32 r, uint256 i, uint256 b, bytes32[2] memory proof) internal pure returns (bool) {
        if (i >= N) return false;
        bytes32 h = leaf(i, b);
        h = i % 2 == 0 ? keccak256(abi.encode(h, proof[0])) : keccak256(abi.encode(proof[0], h));
        h = i < 2 ? keccak256(abi.encode(h, proof[1])) : keccak256(abi.encode(proof[1], h));
        return h == r;
    }

    /// 欄一つの証明を作る(チェーンの外でデータを持つ側がする)
    function proofOf(uint256[4] memory bal, uint256 i) internal pure returns (bytes32[2] memory p) {
        p[0] = leaf(i ^ 1, bal[i ^ 1]);
        if (i < 2) p[1] = keccak256(abi.encode(leaf(2, bal[2]), leaf(3, bal[3])));
        else p[1] = keccak256(abi.encode(leaf(0, bal[0]), leaf(1, bal[1])));
    }
}
