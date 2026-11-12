// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {IMarket} from "../src/IMarket.sol";

// 要件で決めた外向きの約束(ABI)の確認。関数の数とインターフェースIDを書いておき、変わったらこのテストから直す
contract InterfaceTest is Test {
    function test_interfaceId() public pure {
        assertEq(type(IMarket).interfaceId, bytes4(0x7edbb9ad));
    }
}
