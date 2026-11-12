// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";

contract Ops {
    function ops(int8 m, uint8 x) external pure returns (int8 neg, int8 divv, uint8 mul, uint8 pow, uint8 sub, uint8 dec) {
        unchecked {
            neg = -m;          // m = -128
            divv = m / -1;     // -128 / -1
            mul = x * 2;       // 200 * 2
            pow = x ** 2;      // 200 ** 2
            sub = 0 - x;       // 0 - 200 (xは変数)
            uint8 y = 0;
            y--;
            dec = y;
        }
    }
}

contract OpsTest is Test {
    function test_ops() public {
        Ops o = new Ops();
        (int8 neg, int8 divv, uint8 mul, uint8 pow, uint8 sub, uint8 dec) = o.ops(-128, 200);
        console.log("-(-128) =", neg);
        console.log("-128 / -1 =", divv);
        console.log("200 * 2 =", mul);
        console.log("200 ** 2 =", pow);
        console.log("0 - 200 =", sub);
        console.log("0-- =", dec);
    }
}
