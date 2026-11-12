// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, Ratio, Rate} from "../src/Market.sol";

// 第179講: Marketは署名も証明も確認しない。ランタイムコードにSTATICCALL 0個(ecrecoverのようなプリコンパイルを呼ばない)
// 別のチェーンから来たメッセージを受け取る関数なし。お金が出ていく道は預けた人自身のwithdraw一つ
contract NoSigTest is Test {
    function test_noStaticcall() public {
        Market market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        bytes memory code = address(market).code;
        uint256 n = code.length;
        uint256 end = n - 2 - (uint256(uint8(code[n - 2])) << 8 | uint256(uint8(code[n - 1])));
        uint256 staticcalls;
        for (uint256 i = 0; i < end; i++) {
            uint8 op = uint8(code[i]);
            if (op == 0xfa) staticcalls++;
            if (op >= 0x60 && op <= 0x7f) i += op - 0x5f;
        }
        assertEq(staticcalls, 0);
    }
}
