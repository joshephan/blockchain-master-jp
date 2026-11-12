// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";
import {SlotProxy} from "./SlotProxy.sol";

// 第164講: プロキシの後ろのMarketを別のコンストラクタ引数で作った版に変えると、immutableの管理者と利率が変わる。
// 帳簿とスロットマップはプロキシのストレージにそのまま
contract UpgradeTest is Test {
    MockToken token;
    SlotProxy proxy;
    IMarket viaProxy;

    function setUp() public {
        token = new MockToken();
        Market impl = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        proxy = new SlotProxy(address(impl), address(0xAD));
        viaProxy = IMarket(address(proxy));
        viaProxy.addAsset(IERC20(address(token)), Ratio.wrap(75));
        viaProxy.deposit(address(token), 100);
    }

    function test_upgradeSwapsImmutableAdmin() public {
        Market next = new Market(address(0xB0B), Rate.wrap(9e16), Ratio.wrap(80));
        vm.prank(address(0xAD));
        proxy.upgradeTo(address(next));
        assertEq(viaProxy.admin(), address(0xB0B));
        assertEq(Rate.unwrap(viaProxy.interestRate()), 9e16);
        assertEq(Amount.unwrap(viaProxy.totalDeposits(address(token))), 100);
        vm.expectRevert(abi.encodeWithSignature("NotAdmin(address)", address(this)));
        viaProxy.setStatus(IMarket.MarketStatus.Frozen);
    }

    function test_slotMapSameBehindProxy() public {
        viaProxy.setStatus(IMarket.MarketStatus.DepositPaused);
        assertEq(uint256(vm.load(address(proxy), bytes32(uint256(0)))), 1);
        assertEq(uint256(vm.load(address(proxy), bytes32(uint256(1)))), 1);
        assertEq(uint256(vm.load(address(proxy), keccak256(abi.encode(address(token), uint256(4))))), 100);
    }
}
