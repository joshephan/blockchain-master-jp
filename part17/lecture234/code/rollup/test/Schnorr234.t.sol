// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Schnorr234} from "../src/Schnorr234.sol";

contract Schnorr234Test is Test {
    Schnorr234 internal v;
    uint256 internal constant N = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 internal constant X = 0x5ec2e7; // 証明する側だけが知る数
    uint256 internal constant K = 0x7a11d0; // 一度使って捨てる数
    bytes32 internal constant MSG = keccak256("batch 7");

    function setUp() public {
        v = new Schnorr234();
    }

    function _prove(uint256 x, uint256 k, bytes32 m)
        internal
        view
        returns (uint256[2] memory pub, uint256[2] memory r, uint256 s)
    {
        pub = v.mul([uint256(1), 2], x);
        r = v.mul([uint256(1), 2], k);
        uint256 c = v.challenge(pub, r, m);
        s = addmod(k, mulmod(c, x, N), N);
    }

    function test_proofVerifies() public view {
        (uint256[2] memory pub, uint256[2] memory r, uint256 s) = _prove(X, K, MSG);
        uint256 g = gasleft();
        bool ok = v.verify(pub, r, s, MSG);
        console.log("verify gas", g - gasleft());
        console.log("pub.x", pub[0]);
        console.log("s", s);
        assertTrue(ok);
    }

    function test_otherMessageFails() public view {
        (uint256[2] memory pub, uint256[2] memory r, uint256 s) = _prove(X, K, MSG);
        assertFalse(v.verify(pub, r, s, keccak256("batch 8")));
    }

    function test_otherPubFails() public view {
        (, uint256[2] memory r, uint256 s) = _prove(X, K, MSG);
        uint256[2] memory other = v.mul([uint256(1), 2], X + 1);
        assertFalse(v.verify(other, r, s, MSG));
    }

    function test_wrongSecretFails() public view {
        (uint256[2] memory pub, uint256[2] memory r,) = _prove(X, K, MSG);
        uint256 c = v.challenge(pub, r, MSG);
        uint256 s2 = addmod(K, mulmod(c, X + 1, N), N);
        assertFalse(v.verify(pub, r, s2, MSG));
    }

    function test_otherVerifierFails() public {
        (uint256[2] memory pub, uint256[2] memory r, uint256 s) = _prove(X, K, MSG);
        Schnorr234 v2 = new Schnorr234();
        assertFalse(v2.verify(pub, r, s, MSG)); // 問いの数に確認コントラクトのアドレスが入る
    }

    function test_sameCostBigSecret() public view {
        (uint256[2] memory pub, uint256[2] memory r, uint256 s) = _prove(N - 12345, K, MSG);
        uint256 g = gasleft();
        assertTrue(v.verify(pub, r, s, MSG));
        console.log("verify gas big x", g - gasleft());
    }
}
