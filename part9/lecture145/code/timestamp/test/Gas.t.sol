// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";

// 第145講: 第25章のガス測定の手順(アカウント0番、呼び出しの間1秒)をテスト一つに移す。呼び出しごとにsnapshots/Market.jsonに一行
// isolate = true(Foundry 1.8.3のデフォルト)なので、トップレベルの呼び出し一つがトランザクション一つ。記録する値はレシートのgasUsedと同じ基準
contract GasTest is Test {
    address constant A0 = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function test_marketSixCalls() public {
        vm.startPrank(A0, A0);
        MockToken token = new MockToken();
        Market market = new Market(A0, Rate.wrap(5e16), Ratio.wrap(80));
        vm.warp(block.timestamp + 1);
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        vm.snapshotGasLastFrame("Market", "addAsset75");
        vm.warp(block.timestamp + 1);
        market.deposit(address(token), 100);
        vm.snapshotGasLastFrame("Market", "deposit100");
        vm.warp(block.timestamp + 1);
        market.withdraw(address(token), 30);
        vm.snapshotGasLastFrame("Market", "withdraw30");
        vm.warp(block.timestamp + 1);
        market.setStatus(IMarket.MarketStatus.DepositPaused);
        vm.snapshotGasLastFrame("Market", "setStatus1");
        vm.warp(block.timestamp + 1);
        market.setStatus(IMarket.MarketStatus.Active);
        vm.snapshotGasLastFrame("Market", "setStatus0");
        vm.warp(block.timestamp + 1);
        (bool ok,) = address(market).call(abi.encodeCall(IMarket.deposit, (address(token), 0)));
        assertFalse(ok);
        vm.snapshotGasLastFrame("Market", "failDeposit0");
        vm.stopPrank();
    }
}
