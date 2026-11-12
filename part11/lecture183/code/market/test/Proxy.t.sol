// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";
import {SlotProxy} from "./SlotProxy.sol";

// 第160講: Marketをテスト用プロキシの後ろに置いた版。immutable三つは実装コードから、帳簿はプロキシのストレージから出てくるかを確認
contract ProxyTest is Test {
    Market impl;
    SlotProxy proxy;
    IMarket viaProxy;
    MockToken token;

    function setUp() public {
        impl = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        proxy = new SlotProxy(address(impl), address(0xAD));
        viaProxy = IMarket(address(proxy));
        token = new MockToken();
    }

    function test_immutablesFromImplementationCode() public view {
        assertEq(viaProxy.admin(), address(this));
        assertEq(Rate.unwrap(viaProxy.interestRate()), 5e16);
        assertEq(Ratio.unwrap(viaProxy.collateralRatio()), 80);
        assertEq(uint8(viaProxy.status()), 0);
        assertEq(uint256(vm.load(address(proxy), bytes32(uint256(0)))), 0);
    }

    function test_ledgerLivesInProxy() public {
        viaProxy.addAsset(IERC20(address(token)), Ratio.wrap(75));
        viaProxy.deposit(address(token), 100);
        assertEq(Amount.unwrap(viaProxy.totalDeposits(address(token))), 100);
        assertEq(uint256(vm.load(address(proxy), keccak256(abi.encode(address(token), uint256(4))))), 100);
        assertEq(token.balanceOf(address(proxy)), 100);
        assertEq(impl.assetCount(), 0);
        assertEq(Amount.unwrap(impl.totalDeposits(address(token))), 0);
    }
}
