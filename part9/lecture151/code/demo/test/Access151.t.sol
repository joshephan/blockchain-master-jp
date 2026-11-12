// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {AccessRestriction} from "../src/AccessRestriction.sol";
import {Relay, OriginGate, CostsReturn, NoRefund} from "../src/Extra151.sol";

contract Access151Test is Test {
    AccessRestriction a;
    address bob = address(0xB0B);

    function setUp() public {
        a = new AccessRestriction();
    }

    function test_changeOwnerBothWays() public {
        vm.prank(bob);
        vm.expectRevert(AccessRestriction.Unauthorized.selector);
        a.changeOwner(bob);
        a.changeOwner(bob);
        assertEq(a.owner(), bob);
    }

    function test_disownLocksForever() public {
        vm.expectRevert(AccessRestriction.TooEarly.selector);
        a.disown();
        vm.warp(block.timestamp + 6 weeks);
        a.disown();
        assertEq(a.owner(), address(0));
        vm.expectRevert(AccessRestriction.Unauthorized.selector);
        a.changeOwner(address(this));
    }

    function test_disownThenBuyBack() public {
        vm.warp(block.timestamp + 6 weeks);
        a.disown();
        vm.deal(bob, 200 ether);
        vm.prank(bob);
        a.forceOwnerChange{value: 200 ether}(bob);
        assertEq(a.owner(), bob);
    }

    function test_forceOwnerChangeRefund() public {
        vm.deal(bob, 201 ether);
        vm.prank(bob);
        a.forceOwnerChange{value: 201 ether}(bob);
        assertEq(a.owner(), bob);
        console.log("bob balance after", bob.balance);
        console.log("contract balance", address(a).balance);
    }

    function test_conditionAlwaysFalse() public pure {
        for (uint160 x = 0; x < 300; x++) {
            assertFalse(x & 0 == 1);
        }
    }

    function test_returnStillRefunds() public {
        CostsReturn c = new CostsReturn();
        vm.deal(bob, 3 ether);
        vm.prank(bob);
        c.payAndReturn{value: 3 ether}(bob);
        assertEq(c.owner(), bob);
        console.log("bob balance after return", bob.balance);
    }

    function test_refundToRejecterBlocks() public {
        NoRefund n = new NoRefund();
        vm.deal(address(this), 300 ether);
        vm.expectRevert(bytes("buy failed"));
        n.buy{value: 201 ether}(address(a), bob);
        n.buy{value: 200 ether}(address(a), bob);
        assertEq(a.owner(), bob);
    }

    function test_relaySenderAndOrigin() public {
        Relay r = new Relay();
        address owner = address(0xA11CE);
        vm.prank(owner, owner);
        AccessRestriction a2 = new AccessRestriction();
        vm.prank(owner, owner);
        OriginGate g = new OriginGate();
        // ownerがRelayを経由して呼ぶ: msg.senderはRelay、tx.originはowner
        vm.prank(owner, owner);
        vm.expectRevert(AccessRestriction.Unauthorized.selector);
        r.forward(address(a2), abi.encodeCall(AccessRestriction.changeOwner, (bob)));
        vm.prank(owner, owner);
        r.forward(address(g), abi.encodeCall(OriginGate.changeOwner, (bob)));
        assertEq(g.owner(), bob);
        assertEq(a2.owner(), owner);
    }

    receive() external payable {}
}
