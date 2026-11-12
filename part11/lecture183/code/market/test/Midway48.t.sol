// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";

/// @notice transferが動いている間にMarketの帳簿と自分の残高を読んで照合するトークン(テスト用、読むだけ)
contract CheckToken {
    mapping(address => uint256) public balanceOf;
    uint256 public checks;
    uint256 public violations;

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        // 引き出しの途中: 帳簿はすでに減り、トークンはまだMarketにある
        uint256 total = Amount.unwrap(Market(msg.sender).totalDeposits(address(this)));
        checks++;
        if (balanceOf[msg.sender] < total + amount) violations++;
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract MidwayHandler is Test {
    Market public market;
    CheckToken public token;
    address[3] actors = [address(0x1001), address(0x2002), address(0x3003)];

    constructor(Market m, CheckToken t) {
        market = m;
        token = t;
    }

    function deposit(uint256 who, uint256 amount) external {
        address user = actors[who % 3];
        amount = _bound(amount, 1, token.balanceOf(user) + 1);
        if (amount > token.balanceOf(user)) return;
        vm.prank(user);
        market.deposit(address(token), amount);
    }

    function withdraw(uint256 who, uint256 amount) external {
        address user = actors[who % 3];
        (Amount d,,,) = market.positions(address(token), user);
        if (Amount.unwrap(d) == 0) return;
        amount = _bound(amount, 1, Amount.unwrap(d));
        vm.prank(user);
        market.withdraw(address(token), amount);
    }
}

/// @notice 引き出しの途中で読んだ値も不変条件を守るか
contract MidwayInvariantTest is Test {
    Market market;
    CheckToken token;
    MidwayHandler handler;

    function setUp() public {
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        token = new CheckToken();
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        handler = new MidwayHandler(market, token);
        token.mint(address(0x1001), 1000);
        token.mint(address(0x2002), 1000);
        token.mint(address(0x3003), 1000);
        targetContract(address(handler));
    }

    function invariant_midwayLedgerCovered() public view {
        assertEq(token.violations(), 0);
    }

    function afterInvariant() external view {
        assertGt(token.checks(), 0);
    }
}
