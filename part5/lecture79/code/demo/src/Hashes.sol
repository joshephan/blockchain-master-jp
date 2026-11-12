// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Hashes {
    // positions(スロット4)の[asset][user]項目が始まる欄
    function positionSlot(address asset, address user) external pure returns (bytes32) {
        return keccak256(abi.encode(user, keccak256(abi.encode(asset, uint256(4)))));
    }

    function three() external pure returns (bytes32 k, bytes32 s, bytes20 r) {
        k = keccak256("hello");
        s = sha256("hello");
        r = ripemd160("hello");
    }

    function packed() external pure returns (bytes32 p1, bytes32 p2, bytes32 e1, bytes32 e2) {
        p1 = keccak256(abi.encodePacked("a", "bc"));
        p2 = keccak256(abi.encodePacked("ab", "c"));
        e1 = keccak256(abi.encode("a", "bc"));
        e2 = keccak256(abi.encode("ab", "c"));
    }

    // 0~100を一つずつ入れてみて同じハッシュを探す
    function guess(bytes32 h) external pure returns (uint256 n, uint256 tries) {
        for (uint256 i = 0; i <= 100; i++) {
            if (keccak256(abi.encode(i)) == h) return (i, i + 1);
        }
        return (type(uint256).max, 101);
    }

    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) external pure returns (address) {
        return ecrecover(hash, v, r, s);
    }
}
