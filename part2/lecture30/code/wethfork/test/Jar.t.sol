// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test} from "forge-std/Test.sol";
import {Jar} from "../src/Jar.sol";

interface IWETH {
    function balanceOf(address) external view returns (uint256);
}

contract JarForkTest is Test {
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    function setUp() public {
        vm.createSelectFork("mainnet", 26216889);
    }

    function test_Wrap() public {
        Jar jar = new Jar(WETH);
        jar.wrap{value: 1 ether}();
        assertEq(IWETH(WETH).balanceOf(address(jar)), 1 ether);
    }
}
