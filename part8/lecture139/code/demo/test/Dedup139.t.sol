// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Dedup139} from "../src/Dedup139.sol";

// 巻き戻りの行の確認用(expectRevertなしでわざと失敗)
contract Dedup139Fail is Test {
    function test_low() public {
        Dedup139 d = new Dedup139();
        d.a(1);
    }
}
