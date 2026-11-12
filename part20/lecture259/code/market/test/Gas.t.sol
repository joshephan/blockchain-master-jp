// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Base} from "./helpers/Base.sol";

// 計った呼び出し五つのガス(呼び出し一つ、コールドアクセス込み)。版同士を比べるとき同じ順番で計り直す
contract GasTest is Base {
    function setUp() public {
        _deploy(0.05e18);
    }

    function test_gasTable() public {
        vm.prank(bob);
        market.deposit(address(usd), 1000e6);
        emit log_named_uint("deposit", vm.lastFrameGas().gasTotalUsed);
        vm.prank(alice);
        market.deposit(address(col), 1000e18);
        vm.prank(alice);
        market.setCollateral(address(col), true);
        vm.prank(alice);
        market.borrow(address(usd), 700e6);
        emit log_named_uint("borrow", vm.lastFrameGas().gasTotalUsed);
        vm.prank(alice);
        market.repay(address(usd), 100e6);
        emit log_named_uint("repay", vm.lastFrameGas().gasTotalUsed);
        vm.prank(bob);
        market.withdraw(address(usd), 30e6);
        emit log_named_uint("withdraw", vm.lastFrameGas().gasTotalUsed);
        _price(0.7e18);
        vm.prank(carol);
        market.liquidate(alice, address(usd), address(col), 100e6);
        emit log_named_uint("liquidate", vm.lastFrameGas().gasTotalUsed);
    }
}
