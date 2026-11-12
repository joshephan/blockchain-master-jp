// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Airdrop} from "../src/Airdrop.sol";

/// @notice ランダムに叩く規則: aliceが何を入れても200を超えて受け取れない
contract RandomProbeTest is Test {
    Airdrop drop;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        drop = new Airdrop(alice, bob);
    }

    function testFuzz_aliceNeverOverpaid(uint256[] calldata ids) public {
        vm.prank(alice);
        try drop.claim(ids) {} catch {}
        assertLe(drop.paid(alice), 200);
    }
}
