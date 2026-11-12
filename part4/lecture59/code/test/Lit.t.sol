// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Lit} from "../src/Lit.sol";
import {Esc} from "../src/Esc.sol";

contract LitTest is Test {
    Lit lit;

    function setUp() public {
        lit = new Lit();
    }

    function test_quotes() public view {
        (bool same, bool joined, uint256 len) = lit.quotes();
        console.log("same", same);
        console.log("joined", joined);
        console.log("len abc", len);
    }

    function test_lengths() public view {
        (uint256 a, uint256 k, uint256 e) = lit.lengths();
        console.log("abcd", a);
        console.log("ko4", k);
        console.log("emoji", e);
    }

    function test_three() public view {
        (string memory s, bytes memory b, bytes32 x) = lit.threeTypes();
        console.log(s);
        console.logBytes(b);
        console.logBytes32(x);
    }

    function test_hex() public view {
        (bytes memory h, uint256 n) = lit.hexLit();
        console.logBytes(h);
        console.log("len", n);
    }

    function test_cut() public view {
        bytes32 r = lit.cut("Lending Pool for Wrapped Ether and USD Coin");
        console.logBytes32(r);
        console.log(string(abi.encodePacked(r)));
    }

    function test_esc() public {
        Esc e = new Esc();
        (bytes memory a, bytes memory b, uint256 n) = e.f();
        console.logBytes(a);
        console.logBytes(b);
        console.log("len", n);
    }
}
