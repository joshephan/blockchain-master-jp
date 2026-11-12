// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";

// 権限の要件A-01~A-05。テスト名の頭の番号がdesign/requirements.mdの要件番号
// 本体をまだ書いていないテストはvm.skip(true)で飛ばす(失敗に数えない、飛ばした数が出力に残る)
contract AccessTest is Test {
    function test_A01_noKeyMovesDeposits() public {
        vm.skip(true);
    }

    function test_A02_configWaitsForTimelock() public {
        vm.skip(true);
    }

    function test_A03_guardianOnlyPauses() public {
        vm.skip(true);
    }

    function test_A04_unpauseNeedsTimelock() public {
        vm.skip(true);
    }

    function test_A05_noUpgradePath() public {
        vm.skip(true);
    }
}
