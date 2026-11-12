// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Abi141, Pair} from "../src/Abi141.sol";

// 第141講で作成者が追加: コントラクト型で呼んだ外部呼び出しが受け取ったmsg.dataとabi.encodeCallのバイト列の比較
contract Call141Test is Test {
    function test_external_call_bytes() public {
        Abi141 c = new Abi141();
        bytes memory got = c.pairs(Pair(1, 2), 9);
        bytes memory want = abi.encodeCall(Abi141.pairs, (Pair(1, 2), 9));
        console.log("got", got.length, "want", want.length);
        assertEq(got, want);
    }
}
