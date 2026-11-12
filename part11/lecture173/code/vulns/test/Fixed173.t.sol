// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {ToyPool} from "../src/Mev172.sol";
import {SpotOracle, TwapOracle, ToyLender} from "../src/Oracle173.sol";
import {TwapLender} from "../src/Fixed173.sol";

contract Fixed173Test is Test {
    ToyPool p;
    TwapOracle tw;
    ToyLender spotLender;
    TwapLender twapLender;

    function setUp() public {
        p = new ToyPool(1000, 1000);
        vm.warp(1_000_000);
        tw = new TwapOracle(p);
        spotLender = new ToyLender(new SpotOracle(p));
        twapLender = new TwapLender(tw, 1000);
        spotLender.putCollateral(address(this), 100);
        twapLender.putCollateral(address(this), 100);
    }

    // 同じブロック、同じ揺さぶり: スポット価格の貸出は1600、平均価格の貸出は100
    function test_twapLenderHoldsOnSameSwing() public {
        vm.warp(vm.getBlockTimestamp() + 1000);
        tw.update();
        p.swapBForA(3000); // 揺さぶり(同じブロック)
        tw.update();
        uint256 spotBorrow = spotLender.maxBorrowB(address(this));
        uint256 twapBorrow = twapLender.maxBorrowB(address(this));
        emit log_named_uint("spotLender", spotBorrow);
        emit log_named_uint("twapLender", twapBorrow);
        assertEq(spotBorrow, 1600);
        assertEq(twapBorrow, 100);
    }

    // 揺さぶった値が平均に入るには、その値が時間を耐えなければならない(100秒維持)
    function test_twapMovesOnlyWhenHeld() public {
        vm.warp(vm.getBlockTimestamp() + 1000);
        tw.update();
        p.swapBForA(3000);
        tw.update();
        vm.warp(vm.getBlockTimestamp() + 100); // 16.0が100秒間そのまま
        tw.update();
        uint256 twapBorrow = twapLender.maxBorrowB(address(this));
        emit log_named_uint("twapLenderAfter100s", twapBorrow);
        assertEq(twapBorrow, 236);
    }

    // ウィンドウが短ければ値を出さない
    function test_twapLenderNeedsWindow() public {
        vm.expectRevert(TwapLender.WindowTooShort.selector);
        twapLender.maxBorrowB(address(this));
    }
}
