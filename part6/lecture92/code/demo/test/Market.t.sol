// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Market, IERC20, Rate, Ratio, Amount} from "../src/Market.sol";
import {Token} from "../src/Token.sol";

contract MarketTest is Test {
    Market m;
    Token t;
    address admin = address(0xAD);

    function setUp() public {
        m = new Market(admin, Rate.wrap(5e16), Ratio.wrap(80));
        t = new Token();
    }

    function test_admin() public view {
        console.log("this          ", address(this));
        console.log("market.admin()", m.admin());
    }

    function test_addAssetByAdmin() public {
        vm.prank(admin);
        m.addAsset(IERC20(address(t)), Ratio.wrap(75));
        (Ratio r, bool listed) = m.assetConfig(address(t));
        console.log("ratio", Ratio.unwrap(r), "listed", listed);
    }

    function test_addAssetNotAdmin() public {
        vm.expectRevert(bytes("not admin"));
        m.addAsset(IERC20(address(t)), Ratio.wrap(75));
    }

    function test_addAssetAboveCap() public {
        vm.prank(admin);
        vm.expectRevert(bytes("ratio above cap"));
        m.addAsset(IERC20(address(t)), Ratio.wrap(90));
    }

    function test_zeroAdmin() public {
        vm.expectRevert(bytes("admin is zero"));
        new Market(address(0), Rate.wrap(5e16), Ratio.wrap(80));
    }

    function test_depositWithdraw() public {
        vm.prank(admin);
        m.addAsset(IERC20(address(t)), Ratio.wrap(75));
        t.approve(address(m), 100);
        m.deposit(address(t), 100);
        m.withdraw(address(t), 100);
        console.log("totalDeposits", Amount.unwrap(m.totalDeposits(address(t))));
    }
}
