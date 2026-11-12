// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market} from "../src/market/Market.sol";
import {IERC20, Amount, Rate, Ratio} from "../src/market/MarketTypes.sol";
import {StdToken} from "../src/market/StdToken.sol";

// Marketのコピーと承認を使う標準トークンを用意しておく土台
abstract contract Base is Test {
    Market internal market;
    StdToken internal token;
    address internal admin = makeAddr("admin");

    function _setUpMarket() internal {
        market = new Market(admin, Rate.wrap(5e16), Ratio.wrap(80));
        token = new StdToken("Test", "TST", 18, 1_000_000 ether);
        vm.prank(admin);
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
    }

    function _deposited(address user) internal view returns (uint256) {
        (Amount d,,,) = market.positions(address(token), user);
        return Amount.unwrap(d);
    }
}
