// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {V1} from "../src/V1.sol";
import {V2} from "../src/V2.sol";

contract Coder141Test is Test {
    V1 v1; V2 v2;
    function setUp() public { v1 = new V1(); v2 = new V2(); }
    function go(address c, bytes memory cd) internal {
        (bool ok, bytes memory d) = c.call(cd);
        console.log(ok, d.length);
        if (d.length > 0) console.logBytes(d);
    }
    function cd(uint256 x, uint256 b, uint256 a, uint256 s) internal pure returns (bytes memory) {
        return abi.encodePacked(V2.take.selector, x, b, a, s);
    }
    function test_good() public {
        go(address(v1), cd(7, 1, 0x1234, 1));
        go(address(v2), cd(7, 1, 0x1234, 1));
    }
    function test_uint8_1ff() public { go(address(v1), cd(0x1ff, 1, 0x1234, 1)); go(address(v2), cd(0x1ff, 1, 0x1234, 1)); }
    function test_bool_2() public { go(address(v1), cd(7, 2, 0x1234, 1)); go(address(v2), cd(7, 2, 0x1234, 1)); }
    function test_addr_dirty() public { go(address(v1), cd(7, 1, (uint256(0xff) << 248) | 0x1234, 1)); go(address(v2), cd(7, 1, (uint256(0xff) << 248) | 0x1234, 1)); }
    function test_enum_5() public { go(address(v1), cd(7, 1, 0x1234, 5)); go(address(v2), cd(7, 1, 0x1234, 5)); }
    function test_name() public { go(address(v1), abi.encodeCall(V1.name, ())); go(address(v2), abi.encodeCall(V2.name, ())); }
    function test_dirty() public view { console.logBytes(v2.dirty()); }
}
