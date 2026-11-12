// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Token} from "../src/Token.sol";

contract TokenTest is Test {
    Token token;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function setUp() public {
        vm.prank(alice);
        token = new Token(1000);
    }

    function test_TransferEmits() public {
        vm.expectEmit(true, true, false, true);
        emit Transfer(alice, bob, 100);
        vm.prank(alice);
        token.transfer(bob, 100);
    }

    function test_StoreBalance() public {
        bytes32 slot = keccak256(abi.encode(bob, uint256(1)));
        assertEq(vm.load(address(token), slot), bytes32(0));
        vm.store(address(token), slot, bytes32(uint256(500)));
        assertEq(token.balanceOf(bob), 500);
        assertEq(token.totalSupply(), 1000);
        assertEq(token.balanceOf(alice) + token.balanceOf(bob), 1500);
    }

    function test_BobSendsStoredTokens() public {
        bytes32 slot = keccak256(abi.encode(bob, uint256(1)));
        vm.store(address(token), slot, bytes32(uint256(500)));
        vm.prank(bob);
        token.transfer(alice, 500);
        assertEq(token.balanceOf(alice), 1500);
    }

    function test_Deal() public {
        assertEq(bob.balance, 0);
        vm.deal(bob, 5 ether);
        assertEq(bob.balance, 5 ether);
    }
}
