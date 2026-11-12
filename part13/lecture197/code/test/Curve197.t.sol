// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate} from "../src/Market.sol";
import {StdToken} from "./StdToken.sol";
import {TwapFeed} from "./TwapFeed.sol";

// 第197講のデモ: 借りた比率ごとの借りる側の年利と、1年後に預けた側が受け取った比率
contract Curve197Test is Test {
    function _run(uint256 borrowUsd) internal returns (uint256 rate, uint256 supplyGain) {
        StdToken col = new StdToken("Collateral", "COL", 18, 1_000_000e18);
        StdToken usd = new StdToken("Dollar", "USD", 6, 1_000_000e6);
        Market market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(col)), Ratio.wrap(75));
        market.addAsset(IERC20(address(usd)), Ratio.wrap(80));
        market.setPriceFeed(address(col), new TwapFeed(1e18));
        market.setPriceFeed(address(usd), new TwapFeed(1e18));
        vm.warp(vm.getBlockTimestamp() + 1 hours);
        address bob = address(0xB0B);
        usd.transfer(bob, 1000e6);
        vm.startPrank(bob);
        usd.approve(address(market), 1000e6);
        market.deposit(address(usd), 1000e6);
        vm.stopPrank();
        col.approve(address(market), 10_000e18);
        market.deposit(address(col), 10_000e18);
        market.setCollateral(address(col), true);
        if (borrowUsd > 0) market.borrow(address(usd), borrowUsd);
        rate = Rate.unwrap(market.borrowRate(address(usd)));
        vm.warp(vm.getBlockTimestamp() + 365 days);
        supplyGain = market.depositOf(address(usd), bob) - 1000e6;
    }

    function test_curveTable() public {
        uint256[9] memory u = [uint256(0), 200, 400, 600, 800, 850, 900, 950, 1000];
        uint256[9] memory want = [uint256(0), 1.25e16, 2.5e16, 3.75e16, 5e16, 30e16, 55e16, 80e16, 105e16];
        for (uint256 i = 0; i < 9; i++) {
            (uint256 rate, uint256 gain) = _run(u[i] * 1e6);
            assertEq(rate, want[i]);
            console.log("borrowed %s / 1000, borrow rate bps %s, depositor gain (USD 1e-6) %s", u[i], rate / 1e14, gain);
        }
    }
}
