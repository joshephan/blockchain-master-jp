// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Market, IERC20, Amount, Ratio, Position} from "../src/Market.sol";
import {MockToken} from "../src/MockToken.sol";

// デモ用: withdrawの引き算の行(第82講の_debit)だけをuncheckedで囲んだ版 (プロジェクトのコードには入れない)
contract WithdrawDemo is Market {
    function withdrawWrapped(address asset, uint256 amount) external {
        Position storage p = positions[asset][msg.sender];
        unchecked { p.deposited = Amount.wrap(Amount.unwrap(p.deposited) - amount); }
    }
}

contract MarketTest is Test {
    WithdrawDemo m;
    MockToken tk;
    address asset;
    address alice = address(0xA11CE);

    function setUp() public {
        m = new WithdrawDemo();
        tk = new MockToken();
        asset = address(tk);
        m.addAsset(IERC20(asset), Ratio.wrap(75));
        tk.mint(alice, 1000);
        vm.prank(alice);
        tk.approve(address(m), 1000);
        vm.prank(alice);
        m.deposit(asset, 100);
    }

    function test_withdrawChecked() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSignature("Panic(uint256)", 0x11));
        m.withdraw(asset, 101);
    }

    function test_withdrawWrapped() public {
        vm.prank(alice);
        m.withdrawWrapped(asset, 101);
        (Amount d,,,) = m.positions(asset, alice);
        console.log("deposited after withdraw 101:", Amount.unwrap(d));
        assertEq(Amount.unwrap(d), type(uint256).max);
    }

    function test_elapsedBackward() public {
        vm.warp(1000);
        vm.prank(alice);
        m.deposit(asset, 1); // lastUpdate = 1000
        vm.warp(500); // 時計をdepositの時点より前に戻す (テストでのみ可能)
        vm.expectRevert(abi.encodeWithSignature("Panic(uint256)", 0x11));
        m.elapsedOf(asset, alice);
    }
}
