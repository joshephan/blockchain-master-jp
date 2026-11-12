// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Asset, Vault} from "../src/Vault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice 第158講の金庫(OZ 5.4.0 ERC4626)の丸めの方向をランダムな入力で
contract RoundTripFuzzTest is Test {
    Asset asset;
    Vault vault;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address carol = address(0xCA201);

    function setUp() public {
        asset = new Asset();
        vault = new Vault(IERC20(address(asset)));
    }

    // 入れてすぐ全部引き出しても、入れたものより多く受け取ることはない
    function testFuzz_roundTripNeverGains(uint256 first, uint256 donation, uint256 x) public {
        first = bound(first, 1, 1e30);
        donation = bound(donation, 0, 1e30);
        x = bound(x, 1, 1e30);
        asset.mint(alice, first);
        vm.startPrank(alice);
        asset.approve(address(vault), first);
        vault.deposit(first, alice);
        vm.stopPrank();
        asset.mint(bob, donation);
        vm.prank(bob);
        asset.transfer(address(vault), donation);

        asset.mint(carol, x);
        vm.startPrank(carol);
        asset.approve(address(vault), x);
        uint256 shares = vault.deposit(x, carol);
        uint256 back = vault.redeem(shares, carol, carol);
        vm.stopPrank();
        assertLe(back, x);
    }
}
