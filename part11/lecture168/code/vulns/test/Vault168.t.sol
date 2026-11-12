// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {GoodVault, ReentererGood} from "../src/Vault168.sol";

contract Vault168Test is Test {
    // 直した金庫: 同じ攻撃が止まる。攻撃者は自分の分の1イーサだけを受け取り、再入は巻き戻す
    function test_goodVaultBlocks() public {
        GoodVault vault = new GoodVault();
        for (uint160 i = 1; i <= 3; i++) {
            address d = address(i);
            vm.deal(d, 1 ether);
            vm.prank(d);
            vault.deposit{value: 1 ether}();
        }

        ReentererGood att = new ReentererGood(address(vault));
        vm.deal(address(this), 1 ether);
        att.go{value: 1 ether}(); // 同じ再入を仕掛ける

        // 分を送る前に0にするので、コールバックの時点では再び入る分がない
        assertEq(att.hits(), 0); // 再入がまったく起きない
        assertEq(address(att).balance, 1 ether); // 攻撃者は自分の分の1イーサだけ
        assertEq(address(vault).balance, 3 ether); // 善良な預け入れ者三人の3イーサはそのまま
    }
}
