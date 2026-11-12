// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";

// 監査の発見事項の再現テスト。Marketのsrcはそのまま、テストだけを足す

// 移すときに1%の手数料を引くトークン(上場の前提の外のトークン)
contract FeeToken50 {
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 a) external {
        balanceOf[to] += a;
    }

    function transferFrom(address from, address to, uint256 a) external returns (bool) {
        balanceOf[from] -= a;
        balanceOf[to] += a - a / 100;
        return true;
    }

    function transfer(address to, uint256 a) external returns (bool) {
        balanceOf[msg.sender] -= a;
        balanceOf[to] += a - a / 100;
        return true;
    }
}

contract Audit50Test is Test {
    Market market;
    MockToken token;
    address alice = address(0xA11CE);
    address bob = address(0xB0B);

    function setUp() public {
        token = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        token.transfer(alice, 200);
        token.transfer(bob, 200);
    }

    // M-01: 管理者がFrozenをかけると、預けた人は誰も引き出せない。管理者の席を譲ったり空にしたりする関数なし
    function test_M01_frozenLocksWithdraw() public {
        vm.prank(alice);
        market.deposit(address(token), 100);
        market.setStatus(IMarket.MarketStatus.Frozen);
        vm.prank(alice);
        vm.expectRevert(IMarket.MarketFrozen.selector);
        market.withdraw(address(token), 100);
        vm.prank(alice);
        vm.expectRevert(IMarket.MarketFrozen.selector);
        market.withdrawAll(address(token));
        (Amount d,,,) = market.positions(address(token), alice);
        assertEq(Amount.unwrap(d), 100);
        assertEq(token.balanceOf(address(market)), 100);
    }

    // L-01: 手数料トークンを上場すると帳簿と実際の残高が分かれ、最後の引き出しが巻き戻る
    function test_L01_feeTokenLastWithdrawReverts() public {
        FeeToken50 fee = new FeeToken50();
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

    // L-02: depositを通さずに送ったトークンは帳簿に載らず、取り出す関数なし
    function test_L02_directTransferStuck() public {
        vm.prank(alice);
        token.transfer(address(market), 50);
        assertEq(token.balanceOf(address(market)), 50);
        assertEq(Amount.unwrap(market.totalDeposits(address(token))), 0);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(IMarket.InsufficientDeposit.selector, 0, 50));
        market.withdraw(address(token), 50);
    }

    // I-01: useAsCollateralを書く行がないので、collateralCountは常に0
    function test_I01_collateralCountAlwaysZero() public {
        vm.prank(alice);
        market.deposit(address(token), 100);
        assertEq(market.collateralCount(alice), 0);
        (, Amount b,, bool c) = market.positions(address(token), alice);
        assertEq(Amount.unwrap(b), 0);
        assertFalse(c);
        assertEq(Amount.unwrap(market.totalBorrows(address(token))), 0);
    }

    // I-02: 一度も預けたことのない欄のelapsedOfはblock.timestampそのまま
    function test_I02_elapsedOfEmptyPosition() public {
        vm.warp(1_000_000);
        assertEq(market.elapsedOf(address(token), bob), 1_000_000);
    }

    // I-03: collateralCountは上場した資産すべてを回る。資産の数に応じてガスが増える
    function test_I03_collateralCountGas() public {
        uint256 g0 = gasleft();
        market.collateralCount(alice);
        uint256 one = g0 - gasleft();
        for (uint256 i = 0; i < 99; i++) {
            market.addAsset(IERC20(address(uint160(0x1000 + i))), Ratio.wrap(75));
        }
        g0 = gasleft();
        market.collateralCount(alice);
        uint256 hundred = g0 - gasleft();
        emit log_named_uint("assets 1 gas", one);
        emit log_named_uint("assets 100 gas", hundred);
        assertGt(hundred, one * 10);
    }
}
