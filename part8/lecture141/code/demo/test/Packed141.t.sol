// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";

contract Packed141Test is Test {
    function test_doc_example() public pure {
        bytes memory p = abi.encodePacked(int16(-1), bytes1(0x42), uint16(0x03), string("Hello, world!"));
        console.logBytes(p);
        assertEq(p, hex"ffff42000348656c6c6f2c20776f726c6421");
        console.log("packed", p.length, "abi.encode", abi.encode(int16(-1), bytes1(0x42), uint16(0x03), string("Hello, world!")).length);
    }
    function test_collision() public pure {
        bytes memory a = abi.encodePacked("a", "bc");
        bytes memory b = abi.encodePacked("ab", "c");
        console.logBytes(a);
        console.logBytes(b);
        assertEq(keccak256(a), keccak256(b));
        console.logBytes32(keccak256(a));
        console.logBytes32(keccak256(abi.encode("a", "bc")));
        console.logBytes32(keccak256(abi.encode("ab", "c")));
    }
    function test_array_padded() public pure {
        uint8[] memory xs = new uint8[](2);
        xs[0] = 1; xs[1] = 2;
        bytes memory p = abi.encodePacked(xs);
        console.log("uint8[] packed", p.length);
        console.logBytes(p);
        console.logBytes(abi.encodePacked(uint8(1), uint8(2)));
    }
    function test_pad_by_conversion() public pure {
        assertEq(abi.encodePacked(uint16(0x12)), hex"0012");
        console.logBytes(abi.encodePacked(uint16(0x12)));
        console.logBytes(abi.encodePacked(uint256(0x12)));
    }
    function test_nums_collision() public pure {
        // 長さが決まった型同士は、同じバイト列が出ても型の一覧が同じなら値も同じ
        bytes memory a = abi.encodePacked(uint8(1), uint16(0x0203));
        bytes memory b = abi.encodePacked(uint16(0x0102), uint8(3));
        console.logBytes(a);
        console.logBytes(b);
    }
}
