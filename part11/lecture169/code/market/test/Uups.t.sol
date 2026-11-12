// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, Ratio, Rate} from "../src/Market.sol";
import {SlotProxy} from "./SlotProxy.sol";

// 第162講: MarketにはUUPSの関数(proxiableUUID・upgradeToAndCall)がない。テスト用プロキシはコードのないアドレスにも変わる
contract UupsTest is Test {
    function test_marketHasNoProxiableUuid() public {
        Market market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        (bool ok, bytes memory data) = address(market).staticcall(abi.encodeWithSelector(bytes4(0x52d1902d)));
        assertFalse(ok);
        assertEq(data.length, 0);
    }

    function test_slotProxyAcceptsCodelessAddress() public {
        Market market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        SlotProxy proxy = new SlotProxy(address(market), address(this));
        proxy.upgradeTo(address(0xDEAD));
        (bool ok, bytes memory data) = address(proxy).call(abi.encodeWithSignature("admin()"));
        assertTrue(ok);
        assertEq(data.length, 0);
    }
}
