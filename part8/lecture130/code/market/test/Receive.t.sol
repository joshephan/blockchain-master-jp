// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {MockToken} from "../src/MockToken.sol";

// 第99講: Marketにはreceiveもfallbackもない
contract ReceiveTest is Test {
    MockToken token;
    Market market;

    function setUp() public {
        token = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
    }

    function test_rejectsEther() public {
        (bool ok, ) = address(market).call{value: 1 ether}("");
        assertFalse(ok);
        assertEq(address(market).balance, 0);
    }

    function test_rejectsUnknownSelector() public {
        (bool ok, ) = address(market).call(abi.encodeWithSignature("borrow(address,uint256)", address(token), 1));
        assertFalse(ok);
    }

    function test_directTransferNotCounted() public {
        token.transfer(address(market), 50); // depositを通さずに送る
        assertEq(token.balanceOf(address(market)), 50);
        assertEq(Amount.unwrap(market.totalDeposits(address(token))), 0);
    }
}
