// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {MemArr} from "../src/MemArr.sol";
import {Market, Token} from "../src/Market.sol";

contract MemArrTest is Test {
    MemArr m;

    function setUp() public {
        m = new MemArr();
    }

    function test_make() public view {
        uint256[] memory r = m.make(5);
        console.log(r.length);
        for (uint256 i = 0; i < r.length; i++) console.log(r[i]);
    }

    function test_freePtr() public view {
        (uint256 b, uint256 a) = m.freePtr(3);
        console.logBytes32(bytes32(b));
        console.logBytes32(bytes32(a));
        console.log(a - b);
    }

    function test_twoArrays() public view {
        (uint256 a1, uint256 a2, uint256 p) = m.twoArrays();
        console.log(a1);
        console.log(a2);
        console.log(p);
    }

    function test_alias() public view {
        assertEq(m.alias7(), 7);
    }

    function test_evens() public view {
        uint256[] memory xs = new uint256[](6);
        xs[0] = 3; xs[1] = 8; xs[2] = 5; xs[3] = 12; xs[4] = 7; xs[5] = 40;
        uint256[] memory r = m.evens(xs);
        console.log(r.length);
        for (uint256 i = 0; i < r.length; i++) console.log(r[i]);
    }

    function test_market() public {
        Market mk = new Market();
        Token t1 = new Token();
        Token t2 = new Token();
        Token t3 = new Token();
        mk.addAsset(t1);
        mk.addAsset(t2);
        mk.addAsset(t3);
        t1.mint(address(mk), 100);
        t2.mint(address(mk), 2500);
        t3.mint(address(mk), 7);
        uint256[] memory v = mk.reserves();
        for (uint256 i = 0; i < v.length; i++) console.log(v[i]);
    }
}
