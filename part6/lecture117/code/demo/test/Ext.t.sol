// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {ShelfExt} from "../src/Ext.sol";

// 第117講のデモ: forge testはライブラリを先にデプロイしてリンクしてくれる
contract ExtTest is Test {
    function test_put() public {
        ShelfExt s = new ShelfExt();
        s.put(70);
        assertEq(s.peek(), 70);
    }
}
