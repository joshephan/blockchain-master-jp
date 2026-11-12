// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";

// 安全の要件S-01~S-08。テスト名の頭の番号がdesign/requirements.mdの要件番号
// 本体をまだ書いていないテストはvm.skip(true)で飛ばす(失敗に数えない、飛ばした数が出力に残る)
contract SafetyTest is Test {
    function test_S01_exitPathsNeverPaused() public {
        vm.skip(true);
    }

    function test_S02_ledgerBeforeTransfer() public {
        vm.skip(true);
    }

    function test_S03_vaultCoversPromises() public {
        vm.skip(true);
    }

    function test_S04_roundingFavorsMarket() public {
        vm.skip(true);
    }

    function test_S05_assetCountCap() public {
        vm.skip(true);
    }

    function test_S06_zeroShareDepositReverts() public {
        vm.skip(true);
    }

    function test_S07_creditsReceivedAmount() public {
        vm.skip(true);
    }

    function test_S08_noReturnToken() public {
        vm.skip(true);
    }
}
