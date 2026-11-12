// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate, Amount} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";
import {MockToken} from "../src/MockToken.sol";

// 第138講: Marketが受け取るcalldataの形。手で作ったバイト列を低水準のcallで送る
contract CalldataTest is Test {
    MockToken token;
    Market market;

    function setUp() public {
        token = new MockToken();
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        market.addAsset(IERC20(address(token)), Ratio.wrap(75));
    }

    // deposit(address,uint256)は4 + 32 + 32 = 68バイト。後ろにバイトがさらに付いても実行される
    function test_extraBytesIgnored() public {
        bytes memory data = abi.encodeCall(IMarket.deposit, (address(token), 100));
        assertEq(data.length, 68);
        (bool ok, ) = address(market).call(bytes.concat(data, hex"cafebabe"));
        assertTrue(ok);
        assertEq(Amount.unwrap(market.totalDeposits(address(token))), 100);
    }

    // 足りないcalldata、上位バイトが埋まったアドレス、範囲外のenumは引数を読む段階で巻き戻す(巻き戻りデータ0バイト)
    function test_badInputsRevertEmpty() public {
        bytes memory data = abi.encodeCall(IMarket.deposit, (address(token), 100));
        bytes memory short = new bytes(67);
        for (uint256 i = 0; i < 67; i++) short[i] = data[i];
        (bool ok, bytes memory ret) = address(market).call(short);
        assertFalse(ok);
        assertEq(ret.length, 0);

        bytes memory dirty = bytes.concat(data);
        dirty[4] = 0xff; // アドレスの欄32バイトのうち先頭のバイト
        (ok, ret) = address(market).call(dirty);
        assertFalse(ok);
        assertEq(ret.length, 0);

        (ok, ret) = address(market).call(abi.encodeWithSelector(IMarket.setStatus.selector, uint256(3)));
        assertFalse(ok);
        assertEq(ret.length, 0);
        assertEq(uint8(market.status()), 0);
    }
}
