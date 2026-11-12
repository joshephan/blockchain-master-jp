// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Membership, Payment, Points, Shop} from "../src/Shop.sol";
import {PriceLogic, Box} from "../src/Box.sol";

contract ShopTest is Test {
    Membership m;
    Shop shop;
    address alice = address(0xA11CE);

    function setUp() public {
        m = new Membership();
        Payment p = new Payment(m);
        shop = new Shop(p, new Points());
    }

    function test_MemberPays() public {
        m.join(alice);
        vm.prank(alice);
        assertEq(shop.order(1000), 900);
    }

    function test_GuestPays() public {
        vm.prank(alice);
        assertEq(shop.order(1000), 1000);
    }

    function test_PointsIgnored() public {
        m.join(alice);
        vm.prank(alice);
        assertEq(shop.orderWithPoints(1000), 900);
    }
}

contract BoxTest is Test {
    function test_Delegate() public {
        PriceLogic logic = new PriceLogic();
        Box box = new Box();
        box.setVia(address(logic), 500);
        assertEq(box.price(), 500);
        assertEq(logic.price(), 0);
    }
}
