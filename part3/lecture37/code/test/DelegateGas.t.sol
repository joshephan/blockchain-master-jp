// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Ballot} from "../src/Ballot.sol";

contract DelegateGasTest is Test {
    Ballot b;

    function setUp() public {
        bytes32[] memory names = new bytes32[](2);
        names[0] = "coffee";
        names[1] = "tea";
        b = new Ballot(names);
    }

    // 鎖の長さn: v[0] → v[1] → ... → v[n-1] とつながったn人
    // 最後にxがv[0]に委任すると、whileが最後までたどる
    function measure(uint n) internal returns (uint used) {
        address[] memory v = new address[](n);
        for (uint i = 0; i < n; i++) {
            v[i] = address(uint160(0x1000 + i));
            b.giveRightToVote(v[i]);
        }
        for (uint i = 0; i + 1 < n; i++) {
            vm.prank(v[i]);
            b.delegate(v[i + 1]);
        }
        address x = address(0xBEEF);
        b.giveRightToVote(x);
        vm.prank(x);
        uint g = gasleft();
        b.delegate(v[0]);
        used = g - gasleft();
    }

    function test_Chain1() public { console.log("chain 1 :", measure(1)); }
    function test_Chain5() public { console.log("chain 5 :", measure(5)); }
    function test_Chain20() public { console.log("chain 20:", measure(20)); }
}
