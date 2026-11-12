// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";

interface IWETH {
    function deposit() external payable;
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

contract WethForkTest is Test {
    IWETH weth = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address alice = makeAddr("alice");

    function test_Deposit() public {
        uint256 supplyBefore = weth.totalSupply();
        vm.deal(alice, 10 ether);

        vm.prank(alice);
        weth.deposit{value: 10 ether}();

        assertEq(weth.balanceOf(alice), 10 ether);
        assertEq(weth.totalSupply(), supplyBefore + 10 ether);
        console.log("block", block.number);
        console.log("supply before", supplyBefore);
        console.log("supply after ", weth.totalSupply());
    }
}
