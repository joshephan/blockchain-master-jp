// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";

contract EmitWrongTest is Test {
    Token token;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function setUp() public {
        vm.prank(alice);
        token = new Token(1000);
    }

    function test_WrongAmount() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(alice, bob, 99);
        vm.prank(alice);
        token.transfer(bob, 100);
    }
}
