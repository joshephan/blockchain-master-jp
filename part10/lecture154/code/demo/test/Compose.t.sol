// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/market/Market.sol";
import {MockToken} from "../src/market/MockToken.sol";
import {StdToken} from "../src/StdToken.sol";
import {OzToken} from "../src/OzToken.sol";
import {IERC20 as OzIERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Full {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}

contract ComposeTest is Test {
    Market market;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
    }

    function _roundTrip(address token) internal {
        market.addAsset(IERC20(token), Ratio.wrap(75));
        vm.startPrank(alice);
        IERC20Full(token).approve(address(market), 100);
        market.deposit(token, 100);
        market.withdraw(token, 30);
        vm.stopPrank();
        (Amount d,,,) = market.positions(token, alice);
        console.log("deposited", Amount.unwrap(d));
        console.log("market balance", IERC20Full(token).balanceOf(address(market)));
        console.log("allowance left", IERC20Full(token).allowance(alice, address(market)));
    }

    function test_std() public {
        StdToken t = new StdToken("Std Token", "STD", 18, 1000);
        t.transfer(alice, 1000);
        _roundTrip(address(t));
    }

    function test_oz() public {
        OzToken t = new OzToken(1000);
        t.transfer(alice, 1000);
        _roundTrip(address(t));
    }

    function test_stdNoApprove() public {
        StdToken t = new StdToken("Std Token", "STD", 18, 1000);
        t.transfer(alice, 1000);
        market.addAsset(IERC20(address(t)), Ratio.wrap(75));
        vm.prank(alice);
        vm.expectRevert(bytes("insufficient allowance"));
        market.deposit(address(t), 100);
    }

    function test_ozNoApprove() public {
        OzToken t = new OzToken(1000);
        t.transfer(alice, 1000);
        market.addAsset(IERC20(address(t)), Ratio.wrap(75));
        vm.prank(alice);
        (bool ok, bytes memory data) =
            address(market).call(abi.encodeWithSignature("deposit(address,uint256)", address(t), 100));
        assertFalse(ok);
        console.logBytes(data);
    }

    // MockToken: 承認なしで他人の残高を移す
    function test_mockMovesWithoutApproval() public {
        MockToken t = new MockToken();
        t.transfer(alice, 500);
        vm.prank(bob);
        t.transferFrom(alice, bob, 500);
        assertEq(t.balanceOf(bob), 500);
        assertEq(t.balanceOf(alice), 0);
    }

    function test_interfaceIds() public pure {
        console.logBytes4(type(IERC20).interfaceId);
        console.logBytes4(type(IERC20Full).interfaceId);
        console.logBytes4(type(OzIERC20).interfaceId);
    }
}
