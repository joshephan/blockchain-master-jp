// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Child, PayChild, Factory} from "../src/Child.sol";

contract FactoryTest is Test {
    Factory f;

    function setUp() public {
        f = new Factory();
    }

    function test_type() public {
        Child c = f.make(5);
        console.log("address(c)", address(c));
        console.log("c.x()     ", c.x());
    }

    function test_codeLength() public pure {
        console.log("Child creationCode  ", type(Child).creationCode.length);
        console.log("Child runtimeCode   ", type(Child).runtimeCode.length);
        console.log("Factory creationCode", type(Factory).creationCode.length);
        console.log("Factory runtimeCode ", type(Factory).runtimeCode.length);
    }

    function test_createAddress() public {
        uint64 n1 = vm.getNonce(address(f));
        address p1 = vm.computeCreateAddress(address(f), n1);
        Child c1 = f.make(5);
        uint64 n2 = vm.getNonce(address(f));
        address p2 = vm.computeCreateAddress(address(f), n2);
        Child c2 = f.make(5);
        console.log("nonce", n1);
        console.log("predicted", p1);
        console.log("actual   ", address(c1));
        console.log("nonce", n2);
        console.log("predicted", p2);
        console.log("actual   ", address(c2));
        console.log("nonce after", vm.getNonce(address(f)));
        assertEq(p1, address(c1));
        assertEq(p2, address(c2));
    }

    function test_create2Address() public {
        bytes32 s = bytes32(uint256(1));
        address p = vm.computeCreate2Address(
            s, keccak256(abi.encodePacked(type(Child).creationCode, abi.encode(uint256(5)))), address(f)
        );
        address p7 = vm.computeCreate2Address(
            s, keccak256(abi.encodePacked(type(Child).creationCode, abi.encode(uint256(7)))), address(f)
        );
        Child c = f.makeSalted(s, 5);
        console.log("predicted x=5", p);
        console.log("actual    x=5", address(c));
        console.log("predicted x=7", p7);
        assertEq(p, address(c));
    }

    function test_create2Nonce() public {
        bytes32 s = bytes32(uint256(1));
        f.make(5);
        f.make(5);
        Child c = f.makeSalted(s, 5);
        console.log("after two make, salted x=5", address(c));
    }

    function test_sameSaltTwice() public {
        bytes32 s = bytes32(uint256(1));
        f.makeSalted(s, 5);
        f.makeSalted(s, 5);
    }

    function test_callBeforeCreate() public {
        bytes32 s = bytes32(uint256(1));
        address p = vm.computeCreate2Address(
            s, keccak256(abi.encodePacked(type(Child).creationCode, abi.encode(uint256(5)))), address(f)
        );
        console.log("code length before", p.code.length);
        (bool ok, bytes memory ret) = p.call(abi.encodeWithSignature("x()"));
        console.log("call ok", ok);
        console.log("ret length", ret.length);
        f.makeSalted(s, 5);
        console.log("code length after ", p.code.length);
    }

    function test_constructorRevert() public {
        f.make(0);
    }

    function test_rawCreate() public {
        address a = f.rawCreate(0);
        console.log("rawCreate x=0", a);
        address b = f.rawCreate(5);
        console.log("rawCreate x=5", b);
        console.log("made", f.made());
    }

    function test_paid() public {
        PayChild c = f.makePaid{value: 1 ether}(5);
        console.log("PayChild balance", address(c).balance);
    }
}
