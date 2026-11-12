// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";

contract Handler is Test {
    Token public token;
    address[3] public users = [address(0xA11CE), address(0xB0B), address(0xCA11)];

    constructor(Token t) {
        token = t;
    }

    function mint(uint256 who, uint256 amount) public {
        amount = bound(amount, 0, 1e24);
        token.mint(users[who % 3], amount);
    }

    function transfer(uint256 from, uint256 to, uint256 amount) public {
        address sender = users[from % 3];
        amount = bound(amount, 0, token.balanceOf(sender));
        vm.prank(sender);
        token.transfer(users[to % 3], amount);
    }

    function burn(uint256 who, uint256 amount) public {
        address sender = users[who % 3];
        amount = bound(amount, 0, token.balanceOf(sender));
        vm.prank(sender);
        token.burn(amount);
    }
}

contract TokenTest is Test {
    Token public token;
    Handler public handler;

    function setUp() public {
        token = new Token();
        handler = new Handler(token);
        targetContract(address(handler));
    }

    function test_Transfer() public {
        token.mint(address(0xA11CE), 100);
        vm.prank(address(0xA11CE));
        token.transfer(address(0xB0B), 30);
        assertEq(token.balanceOf(address(0xA11CE)), 70);
        assertEq(token.balanceOf(address(0xB0B)), 30);
    }

    function invariant_SupplyEqualsBalances() public view {
        uint256 sum;
        for (uint256 i = 0; i < 3; i++) {
            sum += token.balanceOf(handler.users(i));
        }
        assertEq(token.totalSupply(), sum);
    }
}
