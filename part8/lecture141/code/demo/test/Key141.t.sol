// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
import {Test, console} from "forge-std/Test.sol";
import {Key141} from "../src/Key141.sol";
contract Key141Test is Test {
    function test_keys() public {
        Key141 k = new Key141();
        k.set();
        bytes32 sa = keccak256(abi.encode(address(0x1234), uint256(0)));
        bytes32 ss = keccak256(abi.encodePacked("hi", uint256(1)));
        assertEq(uint256(vm.load(address(k), sa)), 7);
        assertEq(uint256(vm.load(address(k), ss)), 8);
        console.log("abi.encode key", abi.encode(address(0x1234), uint256(0)).length, "packed string key", abi.encodePacked("hi", uint256(1)).length);
    }
}
