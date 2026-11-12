// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract BytesTest is Test {
    function test_Three() public pure {
        bytes32 h = keccak256("alice");
        bytes32 t = "alice-secret";
        bytes32 n = bytes32(uint256(1000));
        console.logBytes32(h);
        console.logBytes32(t);
        console.logBytes32(n);
    }

    function test_Selector() public pure {
        bytes4 sel = IERC20.transfer.selector;
        console.logBytes4(sel);
        assertEq(sel, bytes4(keccak256("transfer(address,uint256)")));
    }

    function test_LengthIndex() public pure {
        bytes32 h = keccak256("alice");
        bytes4 s = 0x12345678;
        console.log("h.length", h.length);
        console.log("s.length", s.length);
        console.logBytes1(h[0]);
        console.logBytes1(s[3]);
    }

    function test_Copy() public pure {
        bytes4 a = 0x11223344;
        bytes4 b = a;
        b = 0x55667788;
        console.logBytes4(a);
        console.logBytes4(b);
    }

    function test_Shrink() public pure {
        console.logBytes2(bytes2(bytes4(0x12345678)));
        console.log(uint16(uint32(0x12345678)));
        console.logBytes4(bytes4(bytes2(0x1234)));
        console.log(uint32(uint16(0x1234)));
    }

    function test_Bits() public pure {
        bytes2 x = 0x12f0;
        bytes2 m = 0xff00;
        console.logBytes2(x & m);
        console.logBytes2(x | m);
        console.logBytes2(x ^ m);
        console.logBytes2(~x);
        console.logBytes2(x << 4);
        console.logBytes2(x >> 4);
    }
}
