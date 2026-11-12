// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {IMarket} from "../src/IMarket.sol";

// 運用の要件O-01~O-02。テスト名の頭の番号がdesign/requirements.mdの要件番号
// 本体をまだ書いていないテストはvm.skip(true)で飛ばす(失敗に数えない、飛ばした数が出力に残る)
contract OpsTest is Test {
    function test_O01_eventsForStateChanges() public {
        vm.skip(true);
    }

    // 監視・インデクサーのツールが呼ぶセレクター。前の版のMarketと同じシグネチャなのでセレクターが同じ
    function test_O02_monitorSelectors() public pure {
        assertEq(IMarket.totalDeposits.selector, bytes4(0xe9403256));
        assertEq(IMarket.assetCount.selector, bytes4(0xeafe7a74));
        assertEq(IMarket.deposit.selector, bytes4(keccak256("deposit(address,uint256)")));
        assertEq(IMarket.Deposited.selector, keccak256("Deposited(address,address,uint256)"));
        assertEq(IMarket.Liquidated.selector, keccak256("Liquidated(address,address,address,address,uint256,uint256)"));
    }
}
