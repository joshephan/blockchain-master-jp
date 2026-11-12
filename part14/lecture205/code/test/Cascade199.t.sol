// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Market, IERC20, IPriceFeed, Ratio, Rate} from "../src/Market.sol";
import {ToyToken} from "./amm/ToyErc20.sol";
import {ToyAmm} from "./amm/ToyAmm.sol";

// 第199講のデモ用の価格の出どころ。プールの価格をpokeのたびに時刻と一緒に記録し、積み上がった価格の合計を返す(プールが変わったあとにpoke)
contract PoolFeed is IPriceFeed {
    ToyAmm public immutable pool;
    uint256[] public times;
    uint256[] public prices;

    constructor(ToyAmm p) {
        pool = p;
        poke();
    }

    function poke() public {
        times.push(block.timestamp);
        prices.push(pool.spotPrice());
    }

    function cumulativePrice(uint32 secondsAgo) external view returns (uint256 sum) {
        uint256 t = block.timestamp - secondsAgo;
        for (uint256 i = 0; i < times.length && times[i] < t; i++) {
            uint256 end = i + 1 < times.length && times[i + 1] < t ? times[i + 1] : t;
            sum += prices[i] * (end - times[i]);
        }
    }
}

// 第199講のデモ: 連鎖清算。四つのアカウントがCOL 1000ずつ預けてUSD 700・650・600・550を借りる(清算ラインを超える価格0.875・0.8125・0.75・0.6875)
// 外でCOLを売ってプールの価格を0.86近くまで下げたあと、清算した側が受け取ったCOLを同じプールに売ると何が起きるか
// 浅いプール(COL・USD 10,000ずつ)と深いプール(1,000,000ずつ)を比べる
contract Cascade199Test is Test {
    ToyToken col;
    ToyToken usd;
    ToyAmm pool;
    PoolFeed feed;
    Market market;
    address[4] borrowers = [address(0xB1), address(0xB2), address(0xB3), address(0xB4)];
    uint256[4] debts = [uint256(700e18), 650e18, 600e18, 550e18];
    address liquidator = address(0x11CD);
    uint256 writtenOff; // 消した借金のせいで減った預け入れ側の持ち分(USD)

    function _setup(uint256 depth) internal {
        col = new ToyToken(18);
        usd = new ToyToken(18);
        pool = new ToyAmm(col, usd, 30);
        col.mint(address(this), depth);
        usd.mint(address(this), depth);
        col.approve(address(pool), type(uint256).max);
        usd.approve(address(pool), type(uint256).max);
        pool.addLiquidity(depth, depth);
        feed = new PoolFeed(pool);
        market = new Market(address(this), Rate.wrap(0), Ratio.wrap(80));
        market.addAsset(IERC20(address(col)), Ratio.wrap(75));
        market.addAsset(IERC20(address(usd)), Ratio.wrap(80));
        market.setPriceFeed(address(col), feed);
        market.setPriceFeed(address(usd), new UsdFeed());
        vm.warp(vm.getBlockTimestamp() + 1 hours);
        feed.poke();
        address lender = address(0x1E4D);
        usd.mint(lender, 10_000e18);
        vm.startPrank(lender);
        usd.approve(address(market), type(uint256).max);
        market.deposit(address(usd), 10_000e18);
        vm.stopPrank();
        for (uint256 i = 0; i < 4; i++) {
            col.mint(borrowers[i], 1000e18);
            vm.startPrank(borrowers[i]);
            col.approve(address(market), type(uint256).max);
            market.deposit(address(col), 1000e18);
            market.setCollateral(address(col), true);
            market.borrow(address(usd), debts[i]);
            vm.stopPrank();
        }
        usd.mint(liquidator, 1_000_000e18);
        vm.startPrank(liquidator);
        usd.approve(address(market), type(uint256).max);
        col.approve(address(pool), type(uint256).max);
        vm.stopPrank();
    }

    function _sell(address who, uint256 amount) internal {
        vm.prank(who);
        pool.swap(address(col), amount, 0);
        feed.poke();
    }

    function _wait() internal {
        vm.warp(vm.getBlockTimestamp() + 30 minutes);
        feed.poke();
    }

    // 一周: 清算ラインを超えたアカウントごとに返せるだけ返し、受け取ったCOLをすぐプールに売る。清算したアカウントの数を返す
    function _round() internal returns (uint256 n) {
        for (uint256 i = 0; i < 4; i++) {
            address b = borrowers[i];
            if (market.depositOf(address(col), b) == 0) {
                // 担保が全部出ていったポジション: 残った借金を消す
                if (market.debtOf(address(usd), b) > 0) {
                    uint256 before = market.depositOf(address(usd), address(0x1E4D));
                    market.writeOffBadDebt(b, address(usd));
                    writtenOff += before - market.depositOf(address(usd), address(0x1E4D));
                }
                continue;
            }
            (, uint256 debtValue) = market.accountHealth(b);
            if (debtValue == 0 || market.liquidationLimit(b) >= debtValue) continue;
            uint256 debt = market.debtOf(address(usd), b);
            vm.startPrank(liquidator);
            try market.liquidate(b, address(usd), address(col), debt) {}
            catch {
                market.liquidate(b, address(usd), address(col), debt / 2);
            }
            market.withdrawAll(address(col));
            vm.stopPrank();
            _sell(liquidator, col.balanceOf(liquidator));
            n++;
        }
    }

    function _cascade(uint256 depth, uint256 shock) internal returns (uint256 total) {
        _setup(depth);
        address seller = address(0x5E11);
        col.mint(seller, shock);
        vm.prank(seller);
        col.approve(address(pool), type(uint256).max);
        _sell(seller, shock);
        console.log("depth %s, pool price after outside sale (1e-4) %s", depth / 1e18, pool.spotPrice() / 1e14);
        _wait();
        for (uint256 r = 1; r <= 10; r++) {
            uint256 n = _round();
            total += n;
            _wait();
            console.log("round %s: liquidations %s, pool price (1e-4) %s", r, n, pool.spotPrice() / 1e14);
            if (n == 0) break;
        }
        uint256 debtSum;
        uint256 colSum;
        for (uint256 i = 0; i < 4; i++) {
            debtSum += market.debtOf(address(usd), borrowers[i]);
            colSum += market.depositOf(address(col), borrowers[i]) * market.priceOf(address(col)) / 1e18;
        }
        console.log("left: debt USD %s, collateral value USD %s", debtSum / 1e18, colSum / 1e18);
        console.log("written off, lender lost USD %s", writtenOff / 1e18);
        console.log("liquidator net USD (signed, 1e-2)");
        console.logInt((int256(usd.balanceOf(liquidator)) - int256(1_000_000e18)) / 1e16);
    }

    function test_thinPoolCascade() public {
        uint256 total = _cascade(10_000e18, 800e18);
        console.log("thin pool total liquidations %s", total);
        assertEq(total, 19);
        assertLt(pool.spotPrice(), 0.47e18);
        assertGt(writtenOff, 0);
    }

    function test_deepPoolStops() public {
        uint256 total = _cascade(1_000_000e18, 80_000e18);
        console.log("deep pool total liquidations %s", total);
        assertEq(total, 1);
        assertGt(pool.spotPrice(), 0.85e18);
        assertEq(writtenOff, 0);
    }
}

// USDの価格の出どころ: 常に1.0
contract UsdFeed is IPriceFeed {
    function cumulativePrice(uint32 secondsAgo) external view returns (uint256) {
        return (block.timestamp - secondsAgo) * 1e18;
    }
}
