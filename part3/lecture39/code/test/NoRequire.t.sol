// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test, console} from "forge-std/Test.sol";
import {Purchase} from "../src/Purchase.sol";
import {PurchaseNoRequire} from "../src/PurchaseNoRequire.sol";
import {RefusingBuyer} from "../src/RefusingBuyer.sol";

contract NoRequireTest is Test {
    function test_NoRequire() public {
        address seller = makeAddr("seller");
        vm.deal(seller, 10 ether);
        vm.prank(seller);
        PurchaseNoRequire p = new PurchaseNoRequire{value: 2 ether}();
        RefusingBuyer rb = new RefusingBuyer{value: 2 ether}(Purchase(address(p)));
        rb.buy();
        rb.received();
        console.log("state", uint256(p.state()));
        console.log("contract", address(p).balance);
        vm.prank(seller);
        p.refundSeller();
        console.log("after refund contract", address(p).balance);
        console.log("seller", seller.balance);
    }
}
