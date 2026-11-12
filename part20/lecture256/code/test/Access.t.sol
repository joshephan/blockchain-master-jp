// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Base} from "./helpers/Base.sol";

// 権限の要件A-01~A-05。テスト名の頭の番号がdesign/requirements.mdの要件番号
// 本体をまだ書いていないテストはvm.skip(true)で飛ばす(失敗に数えない、飛ばした数が出力に残る)
contract AccessTest is Base {
    function setUp() public {
        _deploy(0);
    }

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

    // コードを変える道なし: ランタイムにDELEGATECALL・CALLCODE・SELFDESTRUCTが0個、アップグレード関数なし、EIP-1967の実装スロットは0
    function test_A05_noUpgradePath() public {
        bytes memory code = address(market).code;
        uint256 meta = uint256(uint8(code[code.length - 2])) << 8 | uint256(uint8(code[code.length - 1]));
        uint256 end = code.length - meta - 2;
        uint256 found;
        for (uint256 i = 0; i < end; i++) {
            uint8 op = uint8(code[i]);
            if (op == 0xf4 || op == 0xf2 || op == 0xff) found++;
            if (op >= 0x60 && op <= 0x7f) i += op - 0x5f;
        }
        assertEq(found, 0);
        (bool ok,) = address(market).call(abi.encodeWithSignature("upgradeToAndCall(address,bytes)", address(1), ""));
        assertFalse(ok);
        (ok,) = address(market).call(abi.encodeWithSignature("proxiableUUID()"));
        assertFalse(ok);
        bytes32 implSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        assertEq(vm.load(address(market), implSlot), bytes32(0));
    }
}
