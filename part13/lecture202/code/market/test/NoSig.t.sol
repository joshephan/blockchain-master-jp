// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate} from "../src/Market.sol";
import {StdToken} from "./StdToken.sol";
import {TwapFeed} from "./TwapFeed.sol";

// 第179講: Marketは署名も証明も確認しない。ランタイムコードにSTATICCALL 0個(ecrecoverのようなプリコンパイルを呼ばない)
// 別のチェーンから来たメッセージを受け取る関数なし。お金が出ていく道は預けた人自身のwithdraw一つ
// 第197講: STATICCALL三つは価格の出どころのcumulativePrice二か所とトークンのdecimals一か所。借りる流れでecrecover(アドレス1)の呼び出しは0回
// お金が出ていく道はwithdrawとborrowの二つ
contract NoSigTest is Test {
    function _staticcalls(bytes memory code) internal pure returns (uint256 n) {
        uint256 len = code.length;
        uint256 end = len - 2 - (uint256(uint8(code[len - 2])) << 8 | uint256(uint8(code[len - 1])));
        for (uint256 i = 0; i < end; i++) {
            uint8 op = uint8(code[i]);
            if (op == 0xfa) n++;
            if (op >= 0x60 && op <= 0x7f) i += op - 0x5f;
        }
    }

    function test_staticcallsArePriceReads() public {
        Market market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        assertEq(_staticcalls(address(market).code), 3);
    }

    function test_borrowNeverCallsEcrecover() public {
        Market market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        StdToken col = new StdToken("Collateral", "COL", 18, 1000e18);
        market.addAsset(IERC20(address(col)), Ratio.wrap(75));
        market.setPriceFeed(address(col), new TwapFeed(1e18));
        vm.warp(vm.getBlockTimestamp() + 1 hours);
        col.approve(address(market), 1000e18);
        market.deposit(address(col), 1000e18);
        market.setCollateral(address(col), true);
        vm.expectCall(address(1), "", 0);
        market.borrow(address(col), 100e18);
    }
}
