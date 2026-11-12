// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {ToyL2} from "../src/ToyL2.sol";
import {Exit233} from "../src/Exit233.sol";

/// イーサを受け取らない持ち主(受け取る側の一つがふさがるケース)
contract NoReceive233 {}

contract Exit233Test is Test {
    Exit233 internal exit;
    address internal op = makeAddr("operator");
    address internal alice = makeAddr("alice");
    address internal bob = makeAddr("bob");
    address internal carol = makeAddr("carol");
    address internal dave;
    uint256[4] internal state = [uint256(70 ether), 60 ether, 20 ether, 50 ether];

    function setUp() public {
        vm.warp(1_000_000);
        dave = address(new NoReceive233());
        exit = new Exit233{value: 200 ether}(op, [alice, bob, carol, dave], ToyL2.root(state));
    }

    function test_noEscapeWhileLive() public {
        bytes32[2] memory p = ToyL2.proofOf(state, 0);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Exit233.NotFrozen.selector, 1_000_000 + 7 days));
        exit.escape(0, 70 ether, p);
    }

    function test_escapeAfterFreeze() public {
        vm.warp(1_000_000 + 7 days);
        assertTrue(exit.frozen());
        bytes32[2] memory p = ToyL2.proofOf(state, 0);
        uint256 g = gasleft();
        vm.prank(alice);
        exit.escape(0, 70 ether, p);
        console.log("escape gas", g - gasleft());
        assertEq(alice.balance, 70 ether);
        assertEq(address(exit).balance, 130 ether);
    }

    function test_anyoneCanSendForOwner() public {
        vm.warp(1_000_000 + 7 days);
        bytes32[2] memory p = ToyL2.proofOf(state, 1);
        vm.prank(carol);
        exit.escape(1, 60 ether, p);
        assertEq(bob.balance, 60 ether);
    }

    function test_escapeOnce() public {
        vm.warp(1_000_000 + 7 days);
        bytes32[2] memory p = ToyL2.proofOf(state, 0);
        exit.escape(0, 70 ether, p);
        vm.expectRevert(abi.encodeWithSelector(Exit233.AlreadyExited.selector, 0));
        exit.escape(0, 70 ether, p);
    }

    function test_wrongAmountRejected() public {
        vm.warp(1_000_000 + 7 days);
        bytes32[2] memory p = ToyL2.proofOf(state, 0);
        vm.expectRevert(Exit233.BadProof.selector);
        exit.escape(0, 100 ether, p);
    }

    function test_oneRejecterDoesNotBlockOthers() public {
        vm.warp(1_000_000 + 7 days);
        vm.expectRevert(abi.encodeWithSelector(Exit233.PayFailed.selector, dave));
        exit.escape(3, 50 ether, ToyL2.proofOf(state, 3));
        exit.escape(0, 70 ether, ToyL2.proofOf(state, 0));
        exit.escape(1, 60 ether, ToyL2.proofOf(state, 1));
        exit.escape(2, 20 ether, ToyL2.proofOf(state, 2));
        assertEq(alice.balance + bob.balance + carol.balance, 150 ether);
        assertEq(address(exit).balance, 50 ether);
        assertFalse(exit.exited(3));
    }

    function test_operatorUpdateDelaysFreeze() public {
        vm.warp(1_000_000 + 6 days);
        vm.prank(op);
        exit.update(ToyL2.root(state));
        vm.warp(1_000_000 + 7 days);
        assertFalse(exit.frozen());
    }

    function test_noUpdateAfterFreeze() public {
        vm.warp(1_000_000 + 7 days);
        vm.prank(op);
        vm.expectRevert(Exit233.IsFrozen.selector);
        exit.update(bytes32(uint256(1)));
    }
}
