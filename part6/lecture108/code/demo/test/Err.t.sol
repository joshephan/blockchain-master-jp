// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
import {Test} from "forge-std/Test.sol";
import {Vault, Taker, IVault} from "../src/Err.sol";
contract ErrTest is Test {
    function test_args() public {
        Vault v = new Vault(); Taker t = new Taker();
        t.tryTakeArgs(IVault(address(v)), 5);
        assertEq(t.lastHave(), 3); assertEq(t.lastWant(), 5);
    }
    function test_sameSelector() public pure {
        assertEq(IVault.Short.selector, Vault.Short.selector);
        assertEq(Vault.Short.selector, bytes4(keccak256("Short(uint256,uint256)")));
    }
}
