// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {Jar} from "../src/Jar.sol";

contract MockWETH {
    mapping(address => uint256) public balanceOf;

    function deposit() external payable returns (bool) {
        balanceOf[msg.sender] += msg.value;
        return true;
    }
}

contract JarMockTest is Test {
    function test_WrapMock() public {
        MockWETH mock = new MockWETH();
        Jar jar = new Jar(address(mock));
        jar.wrap{value: 1 ether}();
        assertEq(mock.balanceOf(address(jar)), 1 ether);
    }
}
