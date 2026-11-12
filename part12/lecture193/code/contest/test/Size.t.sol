// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, Ratio, Rate} from "../src/Market.sol";

// 第163講: Marketのランタイムコードはサイズ上限(24,576バイト)内。関数を複数のアドレスに分ける理由はない
contract SizeTest is Test {
    function test_runtimeUnderLimit() public {
        Market market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        assertLt(address(market).code.length, 24576);
    }
}
