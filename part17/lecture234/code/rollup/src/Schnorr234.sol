// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/// 講義用の証明確認コントラクト: 「pub = x·Gであるxを知っている」をxなしで確認
/// 曲線はalt_bn128(プリコンパイル0x06が加算、0x07が乗算)。式一つ: s·G == R + c·pub
contract Schnorr234 {
    uint256 internal constant N = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 internal constant GX = 1;
    uint256 internal constant GY = 2;

    error PrecompileFailed(uint256 which);

    /// 問いの数c: 公開入力全部とチェーン番号・このアドレスをハッシュに入れる
    function challenge(uint256[2] memory pub, uint256[2] memory r, bytes32 message) public view returns (uint256) {
        return uint256(keccak256(abi.encode(block.chainid, address(this), pub, r, message))) % N;
    }

    function verify(uint256[2] calldata pub, uint256[2] calldata r, uint256 s, bytes32 message)
        external
        view
        returns (bool)
    {
        uint256 c = challenge(pub, r, message);
        uint256[2] memory lhs = mul([GX, GY], s);
        uint256[2] memory rhs = add(r, mul(pub, c));
        return lhs[0] == rhs[0] && lhs[1] == rhs[1];
    }

    function mul(uint256[2] memory p, uint256 k) public view returns (uint256[2] memory out) {
        (bool ok, bytes memory ret) = address(0x07).staticcall(abi.encode(p[0], p[1], k));
        if (!ok || ret.length != 64) revert PrecompileFailed(7);
        out = abi.decode(ret, (uint256[2]));
    }

    function add(uint256[2] memory p, uint256[2] memory q) public view returns (uint256[2] memory out) {
        (bool ok, bytes memory ret) = address(0x06).staticcall(abi.encode(p[0], p[1], q[0], q[1]));
        if (!ok || ret.length != 64) revert PrecompileFailed(6);
        out = abi.decode(ret, (uint256[2]));
    }
}
