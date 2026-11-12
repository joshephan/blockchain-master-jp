// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Lit {
    bytes32 public name = "Lending Pool";

    function quotes() external pure returns (bool, bool, uint256) {
        bool same = keccak256(bytes("abc")) == keccak256(bytes('abc'));
        bool joined = keccak256(bytes("ab" "c")) == keccak256(bytes("abc"));
        return (same, joined, bytes("abc").length);
    }

    function lengths() external pure returns (uint256, uint256, uint256) {
        return (
            bytes("abcd").length,
            bytes(unicode"あいうえ").length,
            bytes(unicode"🙂").length
        );
    }

    function threeTypes() external pure returns (string memory, bytes memory, bytes32) {
        string memory s = "abc";
        bytes memory b = "abc";
        bytes32 x = "abc";
        return (s, b, x);
    }

    function hexLit() external pure returns (bytes memory, uint256) {
        bytes memory h = hex"00ff";
        return (h, h.length);
    }

    function cut(string memory s) external pure returns (bytes32) {
        return bytes32(bytes(s));
    }

    function setName(string memory s) external {
        name = bytes32(bytes(s));
    }
}
