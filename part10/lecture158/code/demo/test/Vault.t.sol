// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Asset, Vault} from "../src/Vault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

contract VaultTest is Test {
    Asset asset;
    Vault vault;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address carol = address(0xCA201);

    function setUp() public {
        asset = new Asset();
        vault = new Vault(IERC20(address(asset)));
        asset.mint(alice, 10_000);
        asset.mint(bob, 10_000);
        asset.mint(carol, 10_000);
    }

    function _deposit(address who, uint256 amount) internal returns (uint256 shares) {
        vm.startPrank(who);
        asset.approve(address(vault), amount);
        shares = vault.deposit(amount, who);
        vm.stopPrank();
    }

    function test_firstDeposit() public {
        uint256 s = _deposit(alice, 1000);
        console.log("alice shares", s, "totalAssets", vault.totalAssets());
        console.log("decimals asset/vault", asset.decimals(), vault.decimals());
    }

    // 金庫にトークンを直接送るとtotalAssets(= トークン残高)が増え、シェア一つの価値が変わる
    function test_directTransferMovesPrice() public {
        _deposit(alice, 1000);
        console.log("before: assets for 1000 shares", vault.convertToAssets(1000));
        vm.prank(bob);
        asset.transfer(address(vault), 500);
        console.log("after: totalAssets", vault.totalAssets(), "totalSupply", vault.totalSupply());
        console.log("after: assets for 1000 shares", vault.convertToAssets(1000));
        console.log("bob shares", vault.balanceOf(bob));
    }

    // 丸めの方向: ユーザーに渡す側は切り捨て、ユーザーから受け取る側は切り上げ
    function test_rounding() public {
        _deposit(alice, 1000);
        vm.prank(bob);
        asset.transfer(address(vault), 500);
        console.log("convertToShares(100)", vault.convertToShares(100));
        console.log("previewDeposit(100)", vault.previewDeposit(100));
        console.log("previewWithdraw(100)", vault.previewWithdraw(100));
        console.log("previewMint(66)", vault.previewMint(66));
        console.log("previewRedeem(66)", vault.previewRedeem(66));
        console.log("convertToAssets(66)", vault.convertToAssets(66));
        uint256 s = _deposit(carol, 100);
        console.log("carol deposit 100 -> shares", s);
        vm.prank(carol);
        uint256 back = vault.redeem(s, carol, carol);
        console.log("carol redeem -> assets", back);
    }

    // 最初の預け入れがとても小さいとき、直接送ったトークンが次の預け入れのシェアをどれだけ変えるか(数字だけ)
    function test_tinyFirstDeposit() public {
        _deposit(alice, 1);
        vm.prank(alice);
        asset.transfer(address(vault), 5000);
        uint256 s = _deposit(bob, 4000);
        console.log("bob deposit 4000 -> shares", s);
        console.log("bob can redeem", vault.previewRedeem(vault.balanceOf(bob)));
        console.log("alice can redeem", vault.previewRedeem(vault.balanceOf(alice)));
        console.log("totalAssets", vault.totalAssets());
    }

    function test_selectorsAndEvents() public pure {
        console.logBytes4(IERC4626.deposit.selector);
        console.logBytes4(IERC4626.withdraw.selector);
        console.logBytes4(bytes4(keccak256("deposit(address,uint256)")));
        console.logBytes32(keccak256("Deposit(address,address,uint256,uint256)"));
        console.logBytes32(keccak256("Withdraw(address,address,address,uint256,uint256)"));
        console.logBytes4(type(IERC4626).interfaceId);
    }
}
