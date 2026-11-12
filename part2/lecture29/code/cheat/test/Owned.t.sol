// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Owned} from "../src/Owned.sol";

contract OwnedTest is Test {
    Owned owned;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        vm.prank(alice);
        owned = new Owned();
    }

    function test_OwnerCanSetFee() public {
        vm.prank(alice);
        owned.setFee(30);
        assertEq(owned.fee(), 30);
    }

    function test_OtherCannotSetFee() public {
        vm.expectRevert(abi.encodeWithSelector(Owned.NotOwner.selector, bob));
        vm.prank(bob);
        owned.setFee(30);
    }

    function test_NoPrank() public {
        owned.setFee(30);
    }
}
