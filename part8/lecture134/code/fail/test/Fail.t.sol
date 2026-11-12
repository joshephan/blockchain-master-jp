// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market} from "../src/Market.sol";
import {MockToken} from "../src/MockToken.sol";
import {IERC20, Rate, Ratio} from "../src/MarketTypes.sol";

contract FailTest is Test {
    function test_depositZero() public {
        MockToken t = new MockToken();
        Market m = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        m.addAsset(IERC20(address(t)), Ratio.wrap(75));
        m.deposit(address(t), 0);
    }

    function test_withdrawOver() public {
        MockToken t = new MockToken();
        Market m = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
        m.addAsset(IERC20(address(t)), Ratio.wrap(75));
        m.withdraw(address(t), 150);
    }
}
