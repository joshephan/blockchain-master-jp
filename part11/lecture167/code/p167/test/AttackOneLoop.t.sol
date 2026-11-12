// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {AirdropOneLoop} from "../src/AirdropOneLoop.sol";

/// @notice 同じ攻撃の入力を直した版に入れる
contract AttackOneLoopTest is Test {
    AirdropOneLoop drop;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        drop = new AirdropOneLoop(alice, bob);
    }

    function test_sameIdFourTimesReverts() public {
        uint256[] memory ids = new uint256[](4);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(AirdropOneLoop.AlreadyClaimed.selector, 0));
        drop.claim(ids);
        assertEq(drop.remaining(), 400);
    }
}
