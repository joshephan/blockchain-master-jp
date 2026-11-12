// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate} from "../src/Market.sol";
import {StdToken} from "./StdToken.sol";
import {TwapFeed} from "./TwapFeed.sol";

// 第197講のデモ: 手数料を引くトークン(L-01)を担保として上場し、価格の出どころを付けた版。受け取った量より帳簿が大きい
contract FeeToken197 {
    uint8 public constant decimals = 18;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(uint256 supply) {
        balanceOf[msg.sender] = supply;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _move(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        allowance[from][msg.sender] -= amount;
        _move(from, to, amount);
        return true;
    }

    // 移すたびに1%をバーン
    function _move(address from, address to, uint256 amount) internal {
        balanceOf[from] -= amount;
        balanceOf[to] += amount - amount / 100;
    }
}

contract Audit53Test is Test {
    // 1000を預けるとMarketに入ってきたのは990なのに、帳簿と担保の価値は1000として数える。借りられる上限750
    function test_L01_feeTokenCollateralOverstated() public {
        FeeToken197 fee = new FeeToken197(1000e18);
        StdToken usd = new StdToken("Dollar", "USD", 6, 1_000_000e6);
        Market market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(fee)), Ratio.wrap(75));
        market.addAsset(IERC20(address(usd)), Ratio.wrap(80));
        market.setPriceFeed(address(fee), new TwapFeed(1e18));
        market.setPriceFeed(address(usd), new TwapFeed(1e18));
        vm.warp(vm.getBlockTimestamp() + 1 hours);
        usd.approve(address(market), type(uint256).max);
        market.deposit(address(usd), 1000e6);
        fee.approve(address(market), type(uint256).max);
        market.deposit(address(fee), 1000e18);
        market.setCollateral(address(fee), true);
        assertEq(fee.balanceOf(address(market)), 990e18);
        assertEq(market.depositOf(address(fee), address(this)), 1000e18);
        (uint256 limit,) = market.accountHealth(address(this));
        assertEq(limit, 750e18);
    }
}
