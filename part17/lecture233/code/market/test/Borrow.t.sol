// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, IPriceFeed, Ratio, Rate} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {StdToken} from "./StdToken.sol";
import {TwapFeed} from "./TwapFeed.sol";

// 第197講: 借り入れ・返済、借りた比率の曲線、利息の指数、時間加重平均価格で決める上限
// 担保COL(18桁、担保比率75)、借りるUSD(6桁、担保比率80)。価格の出どころは両方1.0から始まる
contract BorrowTest is Test {
    StdToken col;
    StdToken usd;
    TwapFeed colFeed;
    TwapFeed usdFeed;
    Market market;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        col = new StdToken("Collateral", "COL", 18, 1_000_000e18);
        usd = new StdToken("Dollar", "USD", 6, 1_000_000e6);
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(col)), Ratio.wrap(75));
        market.addAsset(IERC20(address(usd)), Ratio.wrap(80));
        colFeed = new TwapFeed(1e18);
        usdFeed = new TwapFeed(1e18);
        market.setPriceFeed(address(col), colFeed);
        market.setPriceFeed(address(usd), usdFeed);
        vm.warp(vm.getBlockTimestamp() + 1 hours); // 価格の記録がウィンドウ(30分)より長くなるように

        col.transfer(alice, 10_000e18);
        usd.transfer(bob, 10_000e6);
        vm.prank(alice);
        col.approve(address(market), type(uint256).max);
        vm.startPrank(bob);
        usd.approve(address(market), type(uint256).max);
        market.deposit(address(usd), 1000e6);
        vm.stopPrank();
    }

    function _aliceCollateral(uint256 amount) internal {
        vm.startPrank(alice);
        market.deposit(address(col), amount);
        market.setCollateral(address(col), true);
        vm.stopPrank();
    }

    // COL 1000 × 価格1 × 75% = 上限750。USDは6桁なので700e6が価値700e18
    function test_borrowUpToLimit() public {
        _aliceCollateral(1000e18);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IMarket.InsufficientCollateral.selector, 750e18, 751e18));
        market.borrow(address(usd), 751e6);
        vm.prank(alice);
        market.borrow(address(usd), 700e6);
        (uint256 limit, uint256 debt) = market.accountHealth(alice);
        assertEq(limit, 750e18);
        assertEq(debt, 700e18);
        assertEq(usd.balanceOf(alice), 700e6);
        assertEq(market.collateralCount(alice), 1);
    }

    // 借りた比率0・50・80・90・100%で年利0・3.125・5・55・105%
    function test_rateCurve() public {
        _aliceCollateral(10_000e18);
        assertEq(Rate.unwrap(market.borrowRate(address(usd))), 0);
        uint256[4] memory steps = [uint256(500e6), 300e6, 100e6, 100e6];
        uint256[4] memory rates = [uint256(3.125e16), 5e16, 55e16, 105e16];
        for (uint256 i = 0; i < 4; i++) {
            vm.prank(alice);
            market.borrow(address(usd), steps[i]);
            assertEq(Rate.unwrap(market.borrowRate(address(usd))), rates[i]);
        }
        assertEq(market.utilization(address(usd)), 1e18);
    }

    // 借りた比率50%(年3.125%)で1年: 借金500 → 515.625、預けた1000 → 1015.625。返した利息が預けた側に行く
    function test_interestFlowsToDepositor() public {
        _aliceCollateral(1000e18);
        vm.prank(alice);
        market.borrow(address(usd), 500e6);
        vm.warp(vm.getBlockTimestamp() + 365 days);
        assertEq(market.debtOf(address(usd), alice), 515_625_000);
        assertEq(market.depositOf(address(usd), bob), 1_015_625_000);
        usd.transfer(alice, 15_625_000);
        vm.startPrank(alice);
        usd.approve(address(market), type(uint256).max);
        market.repay(address(usd), 515_625_000);
        vm.stopPrank();
        vm.prank(bob);
        market.withdrawAll(address(usd));
        assertEq(usd.balanceOf(bob), 9000e6 + 1_015_625_000);
        assertEq(usd.balanceOf(address(market)), 0);
    }

    // 30分間ずっと1.0だった価格が最後の12秒だけ16.0なら平均は1.1。上限は750ではなく825までしか上がらない
    function test_twapNotSpot() public {
        _aliceCollateral(1000e18);
        colFeed.setPrice(16e18);
        vm.warp(vm.getBlockTimestamp() + 12);
        assertEq(market.priceOf(address(col)), 1.1e18);
        (uint256 limit,) = market.accountHealth(alice);
        assertEq(limit, 825e18);
    }

    // 記録がウィンドウより短い価格の出どころは巻き戻す
    function test_shortHistoryReverts() public {
        StdToken t = new StdToken("New", "NEW", 18, 1e18);
        market.addAsset(IERC20(address(t)), Ratio.wrap(50));
        TwapFeed young = new TwapFeed(1e18);
        market.setPriceFeed(address(t), young);
        uint256 now_ = vm.getBlockTimestamp();
        vm.expectRevert(abi.encodeWithSelector(TwapFeed.ShortHistory.selector, now_, now_ - 30 minutes));
        market.priceOf(address(t));
    }

    // 担保を引き出したり担保から外したりすると上限を確認。700を借りた後にCOL 100を引き出すと上限675
    function test_withdrawKeepsDebtCovered() public {
        _aliceCollateral(1000e18);
        vm.startPrank(alice);
        market.borrow(address(usd), 700e6);
        vm.expectRevert(abi.encodeWithSelector(IMarket.InsufficientCollateral.selector, 675e18, 700e18));
        market.withdraw(address(col), 100e18);
        vm.expectRevert(abi.encodeWithSelector(IMarket.InsufficientCollateral.selector, 0, 700e18));
        market.setCollateral(address(col), false);
        market.withdraw(address(col), 60e18);
        vm.stopPrank();
        (uint256 limit,) = market.accountHealth(alice);
        assertEq(limit, 705e18);
    }

    // 貸し出された分は預けた人も引き出せない
    function test_liquidityLimit() public {
        _aliceCollateral(10_000e18);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IMarket.InsufficientLiquidity.selector, 1000e6, 1001e6));
        market.borrow(address(usd), 1001e6);
        vm.prank(alice);
        market.borrow(address(usd), 700e6);
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IMarket.InsufficientLiquidity.selector, 300e6, 400e6));
        market.withdraw(address(usd), 400e6);
    }

    // 借金より多く払うと借金の分だけ受け取る。全部返した後はNoDebt
    function test_repayCapsAtDebt() public {
        _aliceCollateral(1000e18);
        vm.startPrank(alice);
        market.borrow(address(usd), 700e6);
        usd.approve(address(market), type(uint256).max);
        market.repay(address(usd), 1000e6);
        assertEq(usd.balanceOf(alice), 0);
        assertEq(market.debtOf(address(usd), alice), 0);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NoDebt.selector, address(usd)));
        market.repay(address(usd), 1);
        vm.stopPrank();
    }

    // 凍結した市場: 借り入れは止まり、返済はできる
    function test_frozenStillRepays() public {
        _aliceCollateral(1000e18);
        vm.startPrank(alice);
        market.borrow(address(usd), 100e6);
        usd.approve(address(market), type(uint256).max);
        vm.stopPrank();
        market.setStatus(IMarket.MarketStatus.Frozen);
        vm.startPrank(alice);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotActive.selector, uint8(2)));
        market.borrow(address(usd), 1e6);
        market.repay(address(usd), 100e6);
        vm.stopPrank();
        assertEq(market.debtOf(address(usd), alice), 0);
    }

    // 価格の出どころは管理者のみ、資産ごとに一回。出どころがなければ借りることも担保に使うこともできない
    function test_priceFeedRules() public {
        StdToken t = new StdToken("New", "NEW", 18, 1e18);
        market.addAsset(IERC20(address(t)), Ratio.wrap(50));
        vm.prank(bob);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotAdmin.selector, bob));
        market.setPriceFeed(address(t), colFeed);
        vm.expectRevert(IMarket.ZeroFeed.selector);
        market.setPriceFeed(address(t), IPriceFeed(address(0)));
        vm.expectRevert(abi.encodeWithSelector(IMarket.PriceFeedAlreadySet.selector, address(col)));
        market.setPriceFeed(address(col), usdFeed);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotListed.selector, address(0xBAD)));
        market.setPriceFeed(address(0xBAD), colFeed);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NoPriceFeed.selector, address(t)));
        market.borrow(address(t), 1);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NoPriceFeed.selector, address(t)));
        market.setCollateral(address(t), true);
        (IPriceFeed f, uint8 d) = market.priceConfig(address(usd));
        assertEq(address(f), address(usdFeed));
        assertEq(d, 6);
    }

    // 直接送られたトークンは指数を動かさない。同じブロックで入れて引き出すと入れた分そのまま
    function test_donationAndSameBlock() public {
        _aliceCollateral(1000e18);
        vm.prank(alice);
        market.borrow(address(usd), 500e6);
        vm.warp(vm.getBlockTimestamp() + 30 days);
        vm.prank(bob);
        market.deposit(address(usd), 1e6); // 利息を今まで積む
        (, uint256 s0,) = market.reserves(address(usd));
        usd.transfer(address(market), 5000e6);
        uint256 before = usd.balanceOf(bob);
        vm.startPrank(bob);
        market.deposit(address(usd), 100e6);
        market.withdraw(address(usd), 100e6);
        vm.stopPrank();
        (, uint256 s1,) = market.reserves(address(usd));
        assertEq(s1, s0);
        assertEq(usd.balanceOf(bob), before);
    }

    // 借りて、時間が過ぎ、一部または全部を返す各回ごとに、MarketのUSD + 貸し出された借金 >= 預けた人が引き出す量
    // 借金は切り上げ、預けた取り分は切り捨てで数えるので、等号の側でも足りなくならない
    function test_solvencyTable() public {
        _aliceCollateral(1000e18);
        usd.transfer(alice, 5000e6);
        vm.prank(alice);
        usd.approve(address(market), type(uint256).max);
        uint256[6] memory borrowAmt = [uint256(1), 333_333_333, 700e6, 50e6, 1e6, 123_456_789];
        uint256[6] memory wait = [uint256(1), 7 days, 365 days, 13 hours, 3 * 365 days, 59];
        uint256[6] memory repayAmt = [uint256(0), 100e6, 2000e6, 1, 0, 10e6];
        for (uint256 i = 0; i < 6; i++) {
            vm.startPrank(alice);
            (uint256 limit, uint256 debtValue) = market.accountHealth(alice);
            if (debtValue + borrowAmt[i] * 1e12 <= limit) market.borrow(address(usd), borrowAmt[i]);
            vm.warp(vm.getBlockTimestamp() + wait[i]);
            if (repayAmt[i] > 0 && market.debtOf(address(usd), alice) > 0) market.repay(address(usd), repayAmt[i]);
            vm.stopPrank();
            uint256 cashAndDebt = usd.balanceOf(address(market)) + market.debtOf(address(usd), alice);
            assertGe(cashAndDebt, market.depositOf(address(usd), bob));
        }
    }
}
