// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Bank248, BankNoDebit248, BankNoCredit248} from "../src/Bank248.sol";
import {Drop248} from "../src/Drop248.sol";

contract Res248Test is Test {
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function _sum(Bank248 b) internal view returns (uint256) {
        return b.balanceOf(alice) + b.balanceOf(bob);
    }

    function _run(Bank248 b) internal returns (uint256 sum, uint256 supply) {
        b.mint(alice, 100);
        vm.prank(alice);
        b.move(bob, 30);
        return (_sum(b), b.totalSupply());
    }

    function test_moveKeepsTotal() public {
        (uint256 sum, uint256 supply) = _run(new Bank248());
        assertEq(sum, 100);
        assertEq(supply, 100);
    }

    function test_noDebitMakesMore() public {
        (uint256 sum, uint256 supply) = _run(new BankNoDebit248());
        assertEq(sum, 130);
        assertEq(supply, 100);
    }

    function test_noCreditLosesSome() public {
        (uint256 sum, uint256 supply) = _run(new BankNoCredit248());
        assertEq(sum, 70);
        assertEq(supply, 100);
    }

    function test_memoryAssignIsSameCoin() public {
        (uint256 a, uint256 b) = new Drop248().copyCoin();
        assertEq(a, 7);
        assertEq(b, 7);
    }
}
