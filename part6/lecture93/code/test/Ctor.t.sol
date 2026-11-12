// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {SelfCall} from "../src/SelfCall.sol";
import {SelfPing} from "../src/SelfPing.sol";
import {Vault} from "../src/Vault.sol";
import {Child} from "../src/Child.sol";
import {Empty} from "../src/Empty.sol";
import {Market} from "../src/Market.sol";

contract CtorTest is Test {
    function test_selfCall() public {
        new SelfCall();
    }

    function test_selfPing() public {
        new SelfPing();
    }

    function test_lengths() public pure {
        console.log("Empty creationCode", type(Empty).creationCode.length);
        console.log("Empty runtimeCode ", type(Empty).runtimeCode.length);
        console.log("Vault creationCode", type(Vault).creationCode.length);
        console.log("Vault runtimeCode ", type(Vault).runtimeCode.length);
        console.log("Child creationCode", type(Child).creationCode.length);
        console.log("Child runtimeCode ", type(Child).runtimeCode.length);
        console.log("Market creationCode", type(Market).creationCode.length);
        console.log("Market runtimeCode ", type(Market).runtimeCode.length);
    }
}
