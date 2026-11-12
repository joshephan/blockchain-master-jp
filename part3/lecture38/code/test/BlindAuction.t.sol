// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {BlindAuction} from "../src/BlindAuction.sol";
import {BlindAuctionFlipped} from "../src/BlindAuctionFlipped.sol";

contract BlindAuctionTest is Test {
    BlindAuction a;
    address payable seller = payable(address(0x5E11));
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        a = new BlindAuction(1 days, 1 days, seller);
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
    }

    function test_Commit() public pure {
        bytes32 c = keccak256(abi.encodePacked(uint256(3 ether), false, bytes32("alice-secret")));
        console.logBytes32(c);
    }

    function test_GuessWithoutSecret() public pure {
        bytes32 c = keccak256(abi.encodePacked(uint256(7 ether), false, bytes32(0)));
        for (uint256 v = 1; v <= 10; v++) {
            if (keccak256(abi.encodePacked(v * 1 ether, false, bytes32(0))) == c) {
                console.log("found ether:", v);
            }
        }
    }

    function test_GuessWithSecret() public pure {
        bytes32 c = keccak256(abi.encodePacked(uint256(7 ether), false, bytes32("alice-secret")));
        uint256 hits;
        for (uint256 v = 1; v <= 10; v++) {
            if (keccak256(abi.encodePacked(v * 1 ether, false, bytes32(0))) == c) hits++;
        }
        console.log("hits:", hits);
    }

    function _one(uint256 v, bool f, bytes32 s)
        internal pure returns (uint256[] memory vs, bool[] memory fs, bytes32[] memory ss)
    {
        vs = new uint256[](1); fs = new bool[](1); ss = new bytes32[](1);
        vs[0] = v; fs[0] = f; ss[0] = s;
    }

    function test_WrongSecret() public {
        vm.prank(alice);
        a.bid{value: 5 ether}(keccak256(abi.encodePacked(uint256(3 ether), false, bytes32("alice-secret"))));
        vm.warp(block.timestamp + 1 days + 1);
        (uint256[] memory vs, bool[] memory fs, bytes32[] memory ss) = _one(3 ether, false, bytes32("wrong"));
        uint256 before = alice.balance;
        vm.prank(alice);
        a.reveal(vs, fs, ss);
        console.log("refund (wei):", alice.balance - before);
        console.log("highestBid:", a.highestBid());
    }

    function test_RightSecret() public {
        vm.prank(alice);
        a.bid{value: 5 ether}(keccak256(abi.encodePacked(uint256(3 ether), false, bytes32("alice-secret"))));
        vm.warp(block.timestamp + 1 days + 1);
        (uint256[] memory vs, bool[] memory fs, bytes32[] memory ss) = _one(3 ether, false, bytes32("alice-secret"));
        uint256 before = alice.balance;
        vm.prank(alice);
        a.reveal(vs, fs, ss);
        console.log("refund (wei):", alice.balance - before);
        console.log("highestBid:", a.highestBid());
    }

    function test_EndTooEarly() public {
        vm.warp(block.timestamp + 1 days + 1);
        a.auctionEnd();
    }

    function test_FlippedOrder() public {
        BlindAuctionFlipped f = new BlindAuctionFlipped(1 days, 1 days, seller);
        vm.prank(alice);
        f.bid{value: 5 ether}(keccak256(abi.encodePacked(uint256(3 ether), false, bytes32("alice-secret"))));
        vm.warp(block.timestamp + 1 days + 1);
        (uint256[] memory vs, bool[] memory fs, bytes32[] memory ss) = _one(3 ether, false, bytes32("alice-secret"));
        vm.prank(alice);
        f.reveal(vs, fs, ss);
    }
}
