// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";

// 第144講のデモ: 金額の欄をuint128に狭めた版に2の128乗 + 5を預ける
contract NarrowTest is Test {
    function test_depositOver128() public {
        MockToken token = new MockToken();
        Market market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
        uint256 big = (uint256(1) << 128) + 5;
        deal(address(token), address(this), big);
        (bool ok, bytes memory ret) = address(market).call(abi.encodeCall(IMarket.deposit, (address(token), big)));
        console.log("ok", ok);
        console.logBytes(ret);
        (uint128 d,,,) = market.positions(address(token), address(this));
        console.log("positions deposited", d);
        console.log("totalDeposits", Amount.unwrap(market.totalDeposits(address(token))));
        console.log("market token balance", token.balanceOf(address(market)));
    }
}
