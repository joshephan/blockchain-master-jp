// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Airdrop} from "../src/Airdrop.sol";

/// @notice 作った人が考えたケース
contract AirdropTest is Test {
    Airdrop drop;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        drop = new Airdrop(alice, bob);
    }

    function _ids(uint256 a, uint256 b) internal pure returns (uint256[] memory ids) {
        ids = new uint256[](2);
        ids[0] = a;
        ids[1] = b;
    }

    function test_ownerClaimsBoth() public {
        vm.prank(alice);
        drop.claim(_ids(0, 1));
        assertEq(drop.paid(alice), 200);
        assertEq(drop.remaining(), 200);
    }

    function test_notOwnerReverts() public {
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(Airdrop.NotOwner.selector, 0));
        drop.claim(_ids(0, 1));
    }

    function test_secondClaimReverts() public {
        vm.prank(alice);
        drop.claim(_ids(0, 1));
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(Airdrop.AlreadyClaimed.selector, 0));
        drop.claim(_ids(0, 1));
    }

    function test_everyoneClaims() public {
        vm.prank(alice);
        drop.claim(_ids(0, 1));
        vm.prank(bob);
        drop.claim(_ids(2, 3));
        assertEq(drop.remaining(), 0);
    }

    /// ランダムな番号一つ: 持ち主が受け取ると100
    function testFuzz_ownerClaimsOne(uint256 id) public {
        id = bound(id, 0, 3);
        address who = drop.ownerOf(id);
        uint256[] memory ids = new uint256[](1);
        ids[0] = id;
        vm.prank(who);
        drop.claim(ids);
        assertEq(drop.paid(who), 100);
    }
}
