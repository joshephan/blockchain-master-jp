// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";

// 機能要件F-01~F-10。テスト名の頭の番号がdesign/requirements.mdの要件番号
// 本体をまだ書いていないテストはvm.skip(true)で飛ばす(失敗に数えない、飛ばした数が出力に残る)
contract FunctionalTest is Test {
    function test_F01_depositEarnsInterest() public {
        vm.skip(true);
    }

    function test_F02_withdrawUpToCash() public {
        vm.skip(true);
    }

    function test_F03_collateralToggle() public {
        vm.skip(true);
    }

    function test_F04_borrowWithinLimit() public {
        vm.skip(true);
    }

    function test_F05_repayCapsAtDebt() public {
        vm.skip(true);
    }

    function test_F06_rateCurve() public {
        vm.skip(true);
    }

    function test_F07_liquidateHalfWithBonus() public {
        vm.skip(true);
    }

    function test_F07_underwaterFullLiquidation() public {
        vm.skip(true);
    }

    function test_F08_writeOffSharesLoss() public {
        vm.skip(true);
    }

    function test_F09_twapNotSpot() public {
        vm.skip(true);
    }

    function test_F10_listAssetOnce() public {
        vm.skip(true);
    }
}
