// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Child} from "../src/Child.sol";
import {SaltFactory} from "../src/SaltFactory.sol";

contract Create2Test is Test {
    SaltFactory f;

    function setUp() public {
        f = new SaltFactory();
    }

    function test_threeWays() public {
        bytes32 s = bytes32(uint256(1));
        bytes memory initCode = abi.encodePacked(type(Child).creationCode, abi.encode(uint256(5)));
        address byCheat = vm.computeCreate2Address(s, keccak256(initCode), address(f));
        address bySol = f.predictChild(s, 5);
        Child c = f.makeSalted(s, 5);
        console.log("factory   ", address(f));
        console.log("cheatcode ", byCheat);
        console.log("solidity  ", bySol);
        console.log("actual    ", address(c));
        console.log("init code length", initCode.length);
        assertEq(bySol, address(c));
        assertEq(byCheat, address(c));
    }
}
