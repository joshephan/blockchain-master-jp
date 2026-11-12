// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Token} from "../src/Modular.sol";

contract ModularTest is Test {
    Token token;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        token = new Token();
        vm.store(address(token), keccak256(abi.encode(alice, uint256(0))), bytes32(uint256(100)));
        vm.store(address(token), keccak256(abi.encode(bob, uint256(0))), bytes32(type(uint256).max));
    }

    function test_Transfer() public {
        vm.prank(alice);
        token.transfer(address(0xCAFE), 30);
        assertEq(token.balanceOf(alice), 70);
        assertEq(token.balanceOf(address(0xCAFE)), 30);
    }

    function test_TransferToFullBob() public {
        vm.prank(alice);
        token.transfer(bob, 1);
    }
}
