// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {TestToken, Faker} from "../src/Er141.sol";

contract Er141Test is Test {
    TestToken t;
    Faker f;
    function setUp() public { t = new TestToken(); f = new Faker(); }

    function data(address a, bytes memory cd) internal returns (bytes memory d) {
        (, d) = a.call(cd);
        console.logBytes(d);
    }
    function test_same_bytes() public {
        bytes memory a = data(address(t), abi.encodeCall(TestToken.transfer, (address(1), 150)));
        bytes memory b = data(address(f), abi.encodeCall(Faker.transfer, (address(1), 150)));
        bytes memory c = data(address(f), abi.encodeCall(Faker.raw, (abi.encodeWithSelector(TestToken.InsufficientBalance.selector, 0, 150))));
        assertEq(a, b);
        assertEq(a, c);
        console.logBytes4(TestToken.InsufficientBalance.selector);
    }
    function test_expect_revert_fooled() public {
        vm.expectRevert(abi.encodeWithSelector(TestToken.InsufficientBalance.selector, 0, 150));
        f.transfer(address(1), 150);
    }
    function test_builtin() public {
        data(address(f), abi.encodeCall(Faker.str, ()));
        data(address(f), abi.encodeCall(Faker.panic, (0)));
    }
    function test_reserved() public {
        data(address(f), abi.encodeCall(Faker.raw, (hex"ffffffff")));
        data(address(f), abi.encodeCall(Faker.raw, (hex"00000000")));
    }
}
