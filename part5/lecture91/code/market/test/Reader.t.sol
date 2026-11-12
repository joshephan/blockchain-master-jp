// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio} from "../src/Market.sol";
import {MockToken} from "../src/MockToken.sol";
import {Reader, Liar, IWithdraw} from "../src/Reader.sol";

contract ReaderTest is Test {
    MockToken token;
    Market market;
    Reader reader;
    Liar liar;

    function setUp() public {
        token = new MockToken();
        market = new Market();
        reader = new Reader();
        liar = new Liar();
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
    }

    function test_market() public {
        reader.tryWithdraw(IWithdraw(address(market)), address(token), 30);
    }

    function test_liar() public {
        reader.tryWithdraw(IWithdraw(address(liar)), address(token), 30);
    }

    function test_notListed() public {
        reader.tryWithdraw(IWithdraw(address(market)), address(0), 0);
    }
}
