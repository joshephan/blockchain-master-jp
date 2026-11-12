// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";

contract TextTest is Test {
    function test_KoreanLength() public pure {
        string memory s = unicode"あい";
        console.log(bytes(s).length);
        console.logBytes(bytes(s));
        console.logBytes1(bytes(s)[0]);
    }

    function test_Equal() public pure {
        string memory a = "abc";
        string memory b = "abc";
        string memory c = "abd";
        console.log(keccak256(bytes(a)) == keccak256(bytes(b)));
        console.log(keccak256(bytes(a)) == keccak256(bytes(c)));
    }

    function test_Concat() public pure {
        string memory s = string.concat("Lending ", "Pool");
        console.log(s);
        bytes memory b = bytes.concat(hex"0102", hex"0304");
        console.logBytes(b);
        console.log(b.length);
    }

    function test_BytesMembers() public pure {
        bytes memory b = hex"01020304";
        console.log(b.length);
        console.logBytes1(b[2]);
        b[2] = 0xff;
        console.logBytes(b);
    }
}
