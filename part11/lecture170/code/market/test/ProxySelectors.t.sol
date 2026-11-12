// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, Ratio, Rate} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {SlotProxy} from "./SlotProxy.sol";

// 第161講: プロキシのアップグレード関数のセレクターがMarketにないか、プロキシ自身の関数は実装まで行かずプロキシが受けるかを確認
contract ProxySelectorsTest is Test {
    function test_proxySelectorsNotInMarket() public {
        Market market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        // upgradeTo(address) 0x3659cfe6, upgradeToAndCall(address,bytes) 0x4f1ef286
        (bool ok1, bytes memory d1) = address(market).call(abi.encodeWithSelector(bytes4(0x3659cfe6), address(1)));
        (bool ok2, bytes memory d2) =
            address(market).call(abi.encodeWithSelector(bytes4(0x4f1ef286), address(1), bytes("")));
        assertFalse(ok1);
        assertFalse(ok2);
        assertEq(d1.length + d2.length, 0);
    }

    function test_proxyAnswersItsOwnSelector() public {
        Market market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        SlotProxy proxy = new SlotProxy(address(market), address(0xAD));
        vm.expectRevert(bytes("not admin"));
        proxy.upgradeTo(address(1));
        assertEq(IMarket(address(proxy)).admin(), address(this));
    }
}
