// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Counter247} from "../src/Counter247.sol";
import {CounterData247} from "../src/CounterData247.sol";
import {CounterProgram247} from "../src/CounterProgram247.sol";

contract Acct247Test is Test {
    function test_evmCounterKeepsItsOwnSlot() public {
        Counter247 a = new Counter247();
        Counter247 b = new Counter247();
        a.increment();
        a.increment();
        b.increment();
        assertEq(a.count(), 2);
        assertEq(b.count(), 1);
        assertEq(vm.load(address(a), bytes32(0)), bytes32(uint256(2)));
        assertEq(address(a).code.length, address(b).code.length);
    }

    function test_oneProgramManyAccounts() public {
        CounterProgram247 p = new CounterProgram247();
        CounterData247 x = p.create();
        CounterData247 y = p.create();
        CounterData247 z = p.create();
        p.increment(x);
        p.increment(x);
        p.increment(y);
        assertEq(x.count(), 2);
        assertEq(y.count(), 1);
        assertEq(z.count(), 0);
        assertEq(vm.load(address(p), bytes32(0)), bytes32(0));
        assertEq(x.owner(), address(p));
    }

    function test_onlyOwnerWrites() public {
        CounterProgram247 p = new CounterProgram247();
        CounterData247 x = p.create();
        vm.expectRevert(abi.encodeWithSelector(CounterData247.NotOwner.selector, address(this)));
        x.write(100);
        assertEq(x.count(), 0);
    }

    function test_foreignAccountRejected() public {
        CounterProgram247 p = new CounterProgram247();
        CounterProgram247 q = new CounterProgram247();
        CounterData247 other = q.create();
        vm.expectRevert(abi.encodeWithSelector(CounterProgram247.WrongOwner.selector, address(other), address(q)));
        p.increment(other);
        assertEq(other.count(), 0);
    }
}
