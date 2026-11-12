// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";

// 第150講: 一つのアカウントには送らないトークン(テスト用)
contract RefusingToken {
    mapping(address => uint256) public balanceOf;
    address public refused;

    constructor(address refused_) {
        refused = refused_;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        if (to == refused) revert("refused");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

// 第150講: transferが動いている間にMarketの帳簿と自分の残高を読んでおくトークン(テスト用、読むだけ)
contract PeekToken {
    mapping(address => uint256) public balanceOf;
    uint256 public seenDeposited;
    uint256 public seenTotal;
    uint256 public seenMarketBalance;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        Market m = Market(msg.sender);
        (Amount d,,,) = m.positions(address(this), to);
        seenDeposited = Amount.unwrap(d);
        seenTotal = Amount.unwrap(m.totalDeposits(address(this)));
        seenMarketBalance = balanceOf[msg.sender];
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

// 第150講: Marketは送ってあげず、各自が取りに来る(withdraw)。受け取る側で止まったら、そのアカウントの引き出しだけが失敗するか、
// トークンのコードが動いている間に帳簿がどう見えるかを確認
contract PullTest is Test {
    Market market;
    address one = address(0x1001);
    address two = address(0x2002);

    function setUp() public {
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
    }

    function test_refusedWithdrawStaysWithCaller() public {
        RefusingToken token = new RefusingToken(two);
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        token.mint(one, 100);
        token.mint(two, 50);
        vm.prank(one);
        market.deposit(address(token), 100);
        vm.prank(two);
        market.deposit(address(token), 50);

        vm.prank(two);
        vm.expectRevert(bytes("refused"));
        market.withdraw(address(token), 50);

        vm.prank(one);
        market.withdraw(address(token), 100);

        (Amount d2,,,) = market.positions(address(token), two);
        assertEq(Amount.unwrap(d2), 50);
        assertEq(Amount.unwrap(market.totalDeposits(address(token))), 50);
        assertEq(token.balanceOf(one), 100);
        assertEq(token.balanceOf(address(market)), 50);
    }

    function test_tokenSeesDebitedLedger() public {
        PeekToken token = new PeekToken();
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        token.mint(one, 100);
        vm.prank(one);
        market.deposit(address(token), 100);

        vm.prank(one);
        market.withdraw(address(token), 30);

        assertEq(token.seenDeposited(), 70);
        assertEq(token.seenTotal(), 70);
        assertEq(token.seenMarketBalance(), 100);
        assertEq(token.balanceOf(address(market)), 70);
    }
}
