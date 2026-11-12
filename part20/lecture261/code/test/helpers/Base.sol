// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market} from "../../src/Market.sol";
import {StdToken} from "./StdToken.sol";
import {TwapFeed} from "./TwapFeed.sol";

// テストが共有するポジション。COL(18桁、担保比率75)・USD(6桁、80)、価格の出どころは両方1.0
// 前の版のテストと同じポジション: bob USD 1000を預ける、alice COL 1000を担保にUSD 700を借りる
abstract contract Base is Test {
    StdToken col;
    StdToken usd;
    TwapFeed colFeed;
    TwapFeed usdFeed;
    Market market;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address carol = address(0xCA201);
    address dave = address(0xDA7E);

    function _deploy(uint256 rateAtKink) internal {
        col = new StdToken("Collateral", "COL", 18);
        usd = new StdToken("Dollar", "USD", 6);
        colFeed = new TwapFeed(1e18);
        usdFeed = new TwapFeed(1e18);
        vm.warp(vm.getBlockTimestamp() + 1 hours);
        market = new Market(address(this), address(this), rateAtKink);
        market.listAsset(address(col), colFeed, 75, type(uint256).max);
        market.listAsset(address(usd), usdFeed, 80, type(uint256).max);
        address[4] memory who = [alice, bob, carol, dave];
        for (uint256 i = 0; i < 4; i++) {
            col.mint(who[i], 10_000e18);
            usd.mint(who[i], 10_000e6);
            vm.startPrank(who[i]);
            col.approve(address(market), type(uint256).max);
            usd.approve(address(market), type(uint256).max);
            vm.stopPrank();
        }
    }

    // bob USD 1000を預ける、alice COL 1000を預けて担保としてオンにしUSD 700を借りる
    function _openPosition() internal {
        vm.prank(bob);
        market.deposit(address(usd), 1000e6);
        vm.startPrank(alice);
        market.deposit(address(col), 1000e18);
        market.setCollateral(address(col), true);
        market.borrow(address(usd), 700e6);
        vm.stopPrank();
    }

    // COLの価格を変え、30分たって平均が新しい価格になるようにする
    function _price(uint256 p) internal {
        colFeed.setPrice(p);
        vm.warp(vm.getBlockTimestamp() + 30 minutes);
    }
}
