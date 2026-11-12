// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Abi141, Pair, Bag, IThing} from "../src/Abi141.sol";

contract Abi141Test is Test {
    Abi141 c;
    function setUp() public { c = new Abi141(); }

    function words(bytes memory d) internal pure {
        console.log("len", d.length);
        uint256 start = d.length % 32; // セレクター4バイト
        if (start != 0) console.logBytes(slice(d, 0, start));
        for (uint256 i = start; i < d.length; i += 32) console.logBytes32(bytes32(slice(d, i, 32)));
    }
    function slice(bytes memory d, uint256 s, uint256 n) internal pure returns (bytes memory r) {
        r = new bytes(n);
        for (uint256 i = 0; i < n; i++) r[i] = d[s + i];
    }

    function test_static_tuple() public view {
        bytes memory d = c.pairs(Pair(1, 2), 9);
        words(d);
    }
    function test_dynamic_tuple() public view {
        uint256[] memory xs = new uint256[](2);
        xs[0] = 4; xs[1] = 5;
        bytes memory d = c.bags(Bag(3, xs), 9);
        words(d);
    }
    function test_fn() public view {
        bytes memory d = c.rawFn(IThing(address(0x1234)).ping);
        words(d);
        console.logBytes4(IThing.ping.selector);
    }
    function test_ret() public view {
        (bool ok, bytes memory d) = address(c).staticcall(abi.encodeCall(Abi141.ret, ()));
        assertTrue(ok);
        words(d);
    }
    function test_rets() public view {
        (, bytes memory d1) = address(c).staticcall(abi.encodeCall(Abi141.one, ()));
        words(d1);
        (, bytes memory d3) = address(c).staticcall(abi.encodeCall(Abi141.three, ()));
        words(d3);
    }
    // 同じ[[1,2],[3]]: メモリの配置とABIの形
    function test_nested_mem_vs_abi() public pure {
        uint256[][] memory a = new uint256[][](2);
        a[0] = new uint256[](2); a[0][0] = 1; a[0][1] = 2;
        a[1] = new uint256[](1); a[1][0] = 3;
        uint256 p; uint256 p0; uint256 p1;
        assembly { p := a p0 := mload(add(a, 0x20)) p1 := mload(add(a, 0x40)) }
        console.log("mem a", p);
        console.log("mem a[0] ptr", p0);
        console.log("mem a[1] ptr", p1);
        words(abi.encode(a));
    }
    // 開始位置を形より遠くに置いたバイト列(すき間32バイト)もdecodeは受け取る
    function test_nonstrict_decode() public pure {
        bytes memory d = abi.encodePacked(uint256(0x40), uint256(0xdead), uint256(2), uint256(7), uint256(8));
        uint256[] memory xs = abi.decode(d, (uint256[]));
        console.log(xs.length, xs[0], xs[1]);
        words(abi.encode(xs));
    }
}
