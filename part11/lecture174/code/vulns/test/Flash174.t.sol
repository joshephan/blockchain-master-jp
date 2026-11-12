// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {ToyPool} from "../src/Mev172.sol";
import {SpotOracle, TwapOracle} from "../src/Oracle173.sol";
import {ToyFlashLender, IFlashBorrower} from "../src/Flash174.sol";

contract Flash174Test is Test {
    // 返さなければ巻き戻る
    function test_flashLoanMustRepay() public {
        ToyFlashLender f = new ToyFlashLender(5000);
        NoRepay bad = new NoRepay(f);
        vm.expectRevert(ToyFlashLender.NotRepaid.selector);
        bad.go(1000);
    }
}

contract NoRepay is IFlashBorrower {
    ToyFlashLender flash;

    constructor(ToyFlashLender f) {
        flash = f;
    }

    function go(uint256 amount) external {
        flash.flashLoan(amount);
    }

    function onFlashLoan(uint256) external {}
}
