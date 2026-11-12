// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Items} from "../src/Items.sol";
import {Market, IERC20} from "../src/Market.sol";

contract ItemsTest is Test {
    function test_addItem() public {
        Items s = new Items();
        vm.prank(address(0xA11CE));
        s.addItem(500);
        (address owner, uint256 amount) = s.items(0);
        assertEq(owner, address(0xA11CE));
        assertEq(amount, 500);
    }

    function test_addAssetAdmin() public {
        Market m = new Market();
        m.addAsset(IERC20(address(0x1111)));
        assertEq(m.assetCount(), 1);
    }

    function test_addAssetNotAdmin() public {
        Market m = new Market();
        vm.prank(address(0xBAD));
        vm.expectRevert(bytes("not admin"));
        m.addAsset(IERC20(address(0x1111)));
    }
}
