// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";

// 第106講の確認用: LOG命令一つのガス(メモリは前もって広げておく)
contract LogGasTest is Test {
    function test_logGas() public {
        uint256 g0; uint256 g1;
        assembly { mstore(0x200, 1) }
        assembly { g0 := gas() log0(0x80, 0) g1 := gas() }
        console.log("log0 0B", g0 - g1);
        assembly { g0 := gas() log1(0x80, 0, 1) g1 := gas() }
        console.log("log1 0B", g0 - g1);
        assembly { g0 := gas() log3(0x80, 0, 1, 2, 3) g1 := gas() }
        console.log("log3 0B", g0 - g1);
        assembly { g0 := gas() log0(0x80, 32) g1 := gas() }
        console.log("log0 32B", g0 - g1);
        assembly { g0 := gas() log0(0x80, 96) g1 := gas() }
        console.log("log0 96B", g0 - g1);
        assembly { g0 := gas() log1(0x80, 96, 1) g1 := gas() }
        console.log("log1 96B", g0 - g1);
        assembly { g0 := gas() log3(0x80, 32, 1, 2, 3) g1 := gas() }
        console.log("log3 32B", g0 - g1);
    }
}
