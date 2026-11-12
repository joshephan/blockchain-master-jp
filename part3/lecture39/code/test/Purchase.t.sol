// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test} from "forge-std/Test.sol";
import {Purchase} from "../src/Purchase.sol";
import {PurchaseNoInState} from "../src/PurchaseNoInState.sol";
import {RefusingBuyer} from "../src/RefusingBuyer.sol";

contract PurchaseTest is Test {
    address seller = makeAddr("seller");
    address buyer = makeAddr("buyer");

    function setUp() public {
        vm.deal(seller, 10 ether);
        vm.deal(buyer, 10 ether);
    }

    function test_RevertWhen_BuyerRefusesPayment() public {
        vm.prank(seller);
        Purchase p = new Purchase{value: 2 ether}();
        RefusingBuyer rb = new RefusingBuyer{value: 2 ether}(p);
        rb.buy();

        vm.expectRevert();
        rb.received();

        assertEq(uint256(p.state()), uint256(Purchase.State.Locked));
        assertEq(address(p).balance, 4 ether);
    }

    function test_SellerTakesAllWithoutInState() public {
        vm.prank(seller);
        PurchaseNoInState p = new PurchaseNoInState{value: 2 ether}();
        vm.prank(buyer);
        p.confirmPurchase{value: 2 ether}();

        vm.prank(seller);
        p.abort();

        assertEq(seller.balance, 12 ether);
        assertEq(buyer.balance, 8 ether);
    }
}
