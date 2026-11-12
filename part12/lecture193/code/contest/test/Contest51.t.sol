// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";

// 移すときに1%を引くテスト用トークン(信頼の前提に上場しないと書いた形)
contract FeeToken51 {
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 fee = amount / 100;
        balanceOf[from] -= amount;
        balanceOf[to] += amount - fee;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        uint256 fee = amount / 100;
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount - fee;
        return true;
    }
}

// コンテストの範囲のように置いて、見つけた候補を一つずつ確認するテスト。srcはそのまま
contract Contest51Test is Test {
    Market market;
    MockToken token;
    address admin = address(this);
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        market = new Market(admin, Rate.wrap(5e16), Ratio.wrap(80));
        token = new MockToken();
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        token.transfer(alice, 300);
    }

    // 候補1: 手数料トークンなら帳簿と実際の残高が分かれる -> 信頼の前提(既知の問題)
    function test_feeTokenIsKnownIssue() public {
        FeeToken51 fee = new FeeToken51();
        market.addAsset(IERC20(address(fee)), Ratio.wrap(75));
        fee.mint(alice, 100);
        fee.mint(bob, 100);
        vm.prank(alice);
        market.deposit(address(fee), 100);
        vm.prank(bob);
        market.deposit(address(fee), 100);
        assertEq(Amount.unwrap(market.totalDeposits(address(fee))), 200);
        assertEq(fee.balanceOf(address(market)), 198);
        vm.prank(alice);
        market.withdraw(address(fee), 100);
        assertEq(fee.balanceOf(address(market)), 98);
        vm.prank(bob);
        vm.expectRevert();
        market.withdraw(address(fee), 100);
    }

    // 候補2: 管理者がFrozenにすると預け入れと資産の追加が止まる、引き出しはできる(第178講の版) -> 管理者への信頼(中央の点)
    function test_adminFreezeBlocksDeposit() public {
        vm.prank(alice);
        market.deposit(address(token), 100);
        market.setStatus(IMarket.MarketStatus.Frozen);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IMarket.NotActive.selector, IMarket.MarketStatus.Frozen));
        market.deposit(address(token), 100);
        vm.expectRevert(IMarket.MarketFrozen.selector);
        market.addAsset(IERC20(address(0xA55E7)), Ratio.wrap(50));
        vm.prank(alice);
        market.withdraw(address(token), 100);
        assertEq(token.balanceOf(alice), 300);
    }

    // 候補3: 預けたことのないユーザーのelapsedOfはblock.timestampそのまま -> 表示用関数の値(低)
    function test_elapsedOfNeverDeposited() public {
        vm.warp(1_700_000_000);
        assertEq(market.elapsedOf(address(token), bob), 1_700_000_000);
    }

    // 候補4: useAsCollateral・borrowedをオンにする関数がない -> collateralCount・totalBorrowsは常に0(情報)
    function test_collateralAndBorrowsStayZero() public {
        vm.prank(alice);
        market.deposit(address(token), 100);
        assertEq(market.collateralCount(alice), 0);
        assertEq(Amount.unwrap(market.totalBorrows(address(token))), 0);
    }

    // 候補5: interestForにとても大きな値を入れるとPanic 0x11 -> 状態のない計算関数(情報)
    function test_interestForOverflowPanics() public {
        vm.expectRevert(abi.encodeWithSignature("Panic(uint256)", 0x11));
        market.interestFor(type(uint256).max, Rate.wrap(2), 1);
    }

    // 候補6: DepositPausedでも引き出しはできる -> 仕様(MarketBaseのコメント)どおり、問題ではない
    function test_withdrawWhileDepositPaused() public {
        vm.prank(alice);
        market.deposit(address(token), 100);
        market.setStatus(IMarket.MarketStatus.DepositPaused);
        vm.prank(alice);
        market.withdraw(address(token), 100);
        assertEq(token.balanceOf(alice), 300);
    }
}
