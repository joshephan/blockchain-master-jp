// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
import {Test, console} from "forge-std/Test.sol";

// 第137講に追加したデモ: uint8[10]のメモリサイズ、長さ100のuint8[]とbytes、長さだけ決めたuint[][]の内側の欄の値
contract Mem137x {
    uint8[10] storedM;
    function fp() internal pure returns (uint p) { assembly { p := mload(0x40) } }
    function m10() external pure returns (uint used) {
        uint p = fp(); uint8[10] memory m; m[0] = 1; used = fp() - p;
    }
    function hundred() external pure returns (uint u8arr, uint bts) {
        uint p = fp(); uint8[] memory a = new uint8[](100); a[0] = 1; u8arr = fp() - p;
        p = fp(); bytes memory b = new bytes(100); b[0] = 0x01; bts = fp() - p;
    }
    function inner() external pure returns (uint at, uint w0, uint w1) {
        uint[][] memory x = new uint[][](2);
        assembly { at := x  w0 := mload(add(x, 0x20))  w1 := mload(add(x, 0x40)) }
    }
}

contract Mem137xTest is Test {
    Mem137x m;
    function setUp() public { m = new Mem137x(); }
    function test_m10() public view { console.log("uint8[10] memory", m.m10()); }
    function test_hundred() public view {
        (uint a, uint b) = m.hundred();
        console.log("uint8[] new(100)", a); console.log("bytes new(100)", b);
    }
    function test_inner() public view {
        (uint at, uint a, uint b) = m.inner();
        console.log("x at", at); console.log("x[0] slot", a); console.log("x[1] slot", b);
    }
}
