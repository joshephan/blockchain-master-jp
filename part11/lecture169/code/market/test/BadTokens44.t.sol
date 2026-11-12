// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";

// 第170講・第171講の確認用: 標準を破るトークンの前でMarketがどう動くか。Marketのsrcは変えない。

// falseを返すトークン
contract FalseToken {
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 a) external {
        balanceOf[to] += a;
    }

    function transferFrom(address, address, uint256) external pure returns (bool) {
        return false;
    }

    function transfer(address, uint256) external pure returns (bool) {
        return false;
    }
}

// 何も返さないトークン(USDTの形)
contract NoReturnToken {
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 a) external {
        balanceOf[to] += a;
    }

    function transferFrom(address from, address to, uint256 a) external {
        balanceOf[from] -= a;
        balanceOf[to] += a;
    }

    function transfer(address to, uint256 a) external {
        balanceOf[msg.sender] -= a;
        balanceOf[to] += a;
    }
}

// 移すときに1%の手数料を引くトークン
contract FeeToken {
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 a) external {
        balanceOf[to] += a;
    }

    function transferFrom(address from, address to, uint256 a) external returns (bool) {
        uint256 fee = a / 100;
        balanceOf[from] -= a;
        balanceOf[to] += (a - fee);
        return true;
    }

    function transfer(address to, uint256 a) external returns (bool) {
        uint256 fee = a / 100;
        balanceOf[msg.sender] -= a;
        balanceOf[to] += (a - fee);
        return true;
    }
}

contract BadTokens44Test is Test {
    Market market;
    address user = address(0x1001);

    function setUp() public {
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
    }

    // falseを返すと、Marketのbool確認の行が捕まえて巻き戻す(第170講: 結果を確認する)
    function test_falseTokenDepositReverts() public {
        FalseToken token = new FalseToken();
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        token.mint(user, 100);
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(IMarket.TransferFromFailed.selector, address(token)));
        market.deposit(address(token), 100);
    }

    // 戻り値のないトークンはboolのデコードで巻き戻す(第171講: Marketは標準のboolトークンだけを受け付ける)
    function test_noReturnTokenDepositReverts() public {
        NoReturnToken token = new NoReturnToken();
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        token.mint(user, 100);
        vm.prank(user);
        vm.expectRevert(); // 空の戻り値をboolとしてデコードできず巻き戻す
        market.deposit(address(token), 100);
    }

    // 手数料トークン: 帳簿は100と書くのに実際には99しか入らず、帳簿 > 実際の残高に分かれる(第171講)
    function test_feeTokenLedgerDivergence() public {
        FeeToken token = new FeeToken();
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        token.mint(user, 100);
        vm.prank(user);
        market.deposit(address(token), 100);

        (Amount d,,,) = market.positions(address(token), user);
        assertEq(Amount.unwrap(d), 100); // 帳簿は100
        assertEq(token.balanceOf(address(market)), 99); // 実際に入ってきたのは99
        assertEq(Amount.unwrap(market.totalDeposits(address(token))), 100);
        // 最後の人が100を引き出そうとすると、実際の残高が99なのでトークンのtransferが巻き戻す(underflow)
        vm.prank(user);
        vm.expectRevert();
        market.withdraw(address(token), 100);
    }
}
