// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Probe232} from "../src/Probe232.sol";

contract Probe232Test is Test {
    Probe232 internal probe;

    // alt_bn128 G1の生成点とその逆の点
    uint256 internal constant P = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    // alt_bn128 G2の生成点(EIP-197の順番: xの虚部、xの実部、yの虚部、yの実部)
    uint256 internal constant G2XI = 11559732032986387107991004021392285783925812861821192530917403151452391805634;
    uint256 internal constant G2XR = 10857046999023057135944570762232829481370756359578518086990519993285655852781;
    uint256 internal constant G2YI = 4082367875863433681332203403145435568316851327593401208105741076214120093531;
    uint256 internal constant G2YR = 8495653923123431417604973247489272438418190587263600148770280649306958101930;

    // BLS12-381 G1の生成点の圧縮形式(48バイト)
    bytes internal constant G1_BLS =
        hex"97f1d3a73197d7942695638c4fa9ac0fc3688c4f9774b905a14e3a3f171bac586c55e83ff97a1aeffb3af00adb22c6bb";
    // 無限遠点の圧縮形式(48バイト)
    bytes internal constant INF =
        hex"c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

    function setUp() public {
        probe = new Probe232();
    }

    function _pairs(uint256 k) internal pure returns (bytes memory b) {
        for (uint256 i; i < k; ++i) {
            uint256 y = i % 2 == 0 ? 2 : P - 2; // e(G1,G2)·e(-G1,G2)·... = 1
            b = bytes.concat(b, abi.encode(uint256(1), y, G2XI, G2XR, G2YI, G2YR));
        }
    }

    function test_pairingCost() public view {
        uint256[3] memory ks = [uint256(2), 4, 8];
        for (uint256 i; i < 3; ++i) {
            (bool ok, uint256 r, uint256 g) = probe.pairing(_pairs(ks[i]));
            assertTrue(ok);
            assertEq(r, 1);
            console.log("pairs", ks[i], "gas", g);
        }
    }

    function test_pairingFalse() public view {
        bytes memory b = bytes.concat(_pairs(1), _pairs(1)); // e(G1,G2)·e(G1,G2) != 1
        (bool ok, uint256 r,) = probe.pairing(b);
        assertTrue(ok);
        assertEq(r, 0);
    }

    function _vh(bytes memory commitment) internal pure returns (bytes32) {
        bytes32 h = sha256(commitment);
        return (h & bytes32(type(uint256).max >> 8)) | bytes32(uint256(1) << 248);
    }

    function test_pointEvalConstantBlob() public view {
        // blobの4,096個の欄が全部1なら多項式は定数1: コミットメント = 生成点、どのzでも値は1、証明 = 無限遠点
        bytes memory input = bytes.concat(_vh(G1_BLS), bytes32(uint256(5)), bytes32(uint256(1)), G1_BLS, INF);
        (bool ok, bytes memory ret, uint256 g) = probe.pointEval(input);
        assertTrue(ok);
        (uint256 n, uint256 modulus) = abi.decode(ret, (uint256, uint256));
        console.log("point eval gas", g);
        console.log("returns", n);
        console.logBytes32(bytes32(modulus));
        console.logBytes32(_vh(G1_BLS));
        assertEq(n, 4096);
    }

    function test_pointEvalWrongValue() public view {
        bytes memory input = bytes.concat(_vh(G1_BLS), bytes32(uint256(5)), bytes32(uint256(2)), G1_BLS, INF);
        (bool ok,,) = probe.pointEval(input);
        assertFalse(ok);
    }

    function test_pointEvalWrongHash() public view {
        bytes32 vh = _vh(INF); // 別のコミットメントのハッシュ
        bytes memory input = bytes.concat(vh, bytes32(uint256(5)), bytes32(uint256(1)), G1_BLS, INF);
        (bool ok,,) = probe.pointEval(input);
        assertFalse(ok);
    }
}
