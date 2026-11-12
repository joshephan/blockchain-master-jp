// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Owned} from "../src/Owned.sol";

contract RevertWrongTest is Test {
    Owned owned;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        vm.prank(alice);
        owned = new Owned();
    }

    function test_WrongReason() public {
        vm.expectRevert(abi.encodeWithSelector(Owned.NotOwner.selector, alice));
        vm.prank(bob);
        owned.setFee(30);
    }
}
