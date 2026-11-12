// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {Voucher} from "../src/Voucher.sol";

contract VoucherTest is Test {
    // anvilのデフォルトアカウント1番 (第27講の公開されたテスト用の鍵)
    uint256 constant ALICE_KEY = 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d;
    Voucher voucher;

    function setUp() public {
        voucher = new Voucher(vm.addr(ALICE_KEY));
    }

    function test_chainId() public {
        console.log("chainid", block.chainid);
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(ALICE_KEY, voucher.digestNoChain(100, 1));
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(ALICE_KEY, voucher.digestWithChain(100, 1));
        console.log("noChain  ", voucher.checkNoChain(100, 1, v1, r1, s1));
        console.log("withChain", voucher.checkWithChain(100, 1, v2, r2, s2));

        vm.chainId(5);
        console.log("chainid", block.chainid);
        console.log("noChain  ", voucher.checkNoChain(100, 1, v1, r1, s1));
        console.log("withChain", voucher.checkWithChain(100, 1, v2, r2, s2));
    }
}
