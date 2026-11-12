// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {DoubleMul, DoubleShl, DoubleUnchecked} from "../src/Double.sol";

contract DoubleGasTest is Test {
    DoubleMul m;
    DoubleShl s;
    DoubleUnchecked u;

    function setUp() public {
        m = new DoubleMul();
        s = new DoubleShl();
        u = new DoubleUnchecked();
    }

    function test_Double() public view {
        m.double(12345);
        s.double(12345);
        u.double(12345);
    }
}
