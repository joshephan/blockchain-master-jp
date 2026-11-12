// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate} from "../src/Market.sol";

/// @notice 第123講の変形版の利息計算(アセンブリ、オーバーフローチェックなし)。テストの中でだけ使う
library AsmMath {
    function interestFor(uint256 amount, uint256 rate, uint256 elapsed) internal pure returns (uint256 r) {
        assembly {
            r := div(div(mul(mul(amount, rate), elapsed), 31536000), 1000000000000000000)
        }
    }
}

/// @notice 利息の計算を性質で叩く
contract InterestFuzzTest is Test {
    Market market;

    function setUp() public {
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
    }

    // 最初の版: 三つのうち一つでも0ならあふれないとみなす
    function _overflowsDraft(uint256 a, uint256 r, uint256 e) internal pure returns (bool) {
        if (a == 0 || r == 0 || e == 0) return false;
        if (a > type(uint256).max / r) return true;
        return a * r > type(uint256).max / e;
    }

    // 直した版: 式は(a * r) * eの順に計算。a * rで先にあふれることがある
    function _overflows(uint256 a, uint256 r, uint256 e) internal pure returns (bool) {
        if (r != 0 && a > type(uint256).max / r) return true;
        if (e != 0 && a * r > type(uint256).max / e) return true;
        return false;
    }

    // 最初の版の性質: あふれたら巻き戻り、あふれなければ式どおりの値
    function testFuzz_interestDraft(uint256 a, uint256 r, uint256 e) public view {
        try market.interestFor(a, Rate.wrap(r), e) returns (uint256 v) {
            assertFalse(_overflowsDraft(a, r, e));
            assertEq(v, a * r * e / 365 days / 1e18);
        } catch (bytes memory err) {
            assertTrue(_overflowsDraft(a, r, e));
            assertEq(err, abi.encodeWithSignature("Panic(uint256)", 0x11));
        }
    }

    // 直した性質: あふれたらPanic 0x11で巻き戻り、あふれなければ式どおりの値。間違った値を返すことはない
    function testFuzz_interestRevertsOrExact(uint256 a, uint256 r, uint256 e) public view {
        try market.interestFor(a, Rate.wrap(r), e) returns (uint256 v) {
            assertFalse(_overflows(a, r, e));
            assertEq(v, a * r * e / 365 days / 1e18);
        } catch (bytes memory err) {
            assertTrue(_overflows(a, r, e));
            assertEq(err, abi.encodeWithSignature("Panic(uint256)", 0x11));
        }
    }

    // 同じ性質をアセンブリ版にかけると
    function testFuzz_asmNeverWrongValue(uint256 a, uint256 r, uint256 e) public pure {
        if (_overflows(a, r, e)) {
            // あふれる入力で値を返すと、その値は式と違う
            uint256 v = AsmMath.interestFor(a, r, e);
            assertEq(v, type(uint256).max, "asm returned a value for an overflowing input");
        }
    }

    // 倍率の約束: 年利100%(1e18)で1年なら利息 = 元本
    function testFuzz_rateScaleOneYear(uint256 a) public view {
        a = bound(a, 0, type(uint256).max / 1e18 / 365 days);
        assertEq(market.interestFor(a, Rate.wrap(1e18), 365 days), a);
    }

    // pure関数: どのブロックで呼んでも同じ答え
    function testFuzz_pureSameAnyBlock(uint256 a, uint256 r, uint256 e, uint256 ts, uint256 bn) public {
        a = bound(a, 0, 1e30);
        r = bound(r, 0, 1e18);
        e = bound(e, 0, 100 * 365 days);
        uint256 before = market.interestFor(a, Rate.wrap(r), e);
        vm.warp(bound(ts, 1, type(uint64).max));
        vm.roll(bound(bn, 1, type(uint64).max));
        assertEq(market.interestFor(a, Rate.wrap(r), e), before);
    }
}
