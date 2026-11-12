// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {
    GoodToken, NoReturnToken, FeeToken, StrictConsumer, SafeConsumer, SafeTransferLib
} from "../src/Tokens171.sol";

contract Tokens171Test is Test {
    // boolを信じる利用側: 標準トークンは通り、戻り値のないトークンはデコードで巻き戻す
    function test_strictConsumerBreaksOnNoReturn() public {
        StrictConsumer c = new StrictConsumer();

        GoodToken good = new GoodToken();
        good.mint(address(c), 100);
        assertTrue(c.send(address(good), address(0x1), 40));

        NoReturnToken nr = new NoReturnToken();
        nr.mint(address(c), 100);
        // transferが何も返さないので、boolのデコードが巻き戻す
        vm.expectRevert();
        c.send(address(nr), address(0x1), 40);
    }

    // SafeTransferLib: 戻り値のないトークンも成功として処理し、実際に移される
    function test_safeConsumerHandlesNoReturn() public {
        SafeConsumer c = new SafeConsumer();
        NoReturnToken nr = new NoReturnToken();
        nr.mint(address(c), 100);
        c.send(address(nr), address(0x1), 40);
        assertEq(nr.balanceOf(address(0x1)), 40);
        assertEq(nr.balanceOf(address(c)), 60);
    }

    // コードのないアドレスに送るとSafeTransferLibが止める(静かな成功を防ぐ)
    function test_safeTransferRevertsOnNoCode() public {
        SafeConsumer c = new SafeConsumer();
        address noCode = address(0xDEAD);
        vm.expectRevert(abi.encodeWithSelector(SafeTransferLib.SafeTransferFailed.selector, noCode));
        c.send(noCode, address(0x1), 1);
    }

    // 手数料トークン: 送った量と受け取った量が違う(帳簿と実際の残高が分かれる)
    function test_feeTokenDivergence() public {
        FeeToken fee = new FeeToken();
        address from = address(0x1);
        address pool = address(0x2);
        fee.mint(from, 1000);
        vm.prank(from);
        fee.transferFrom(from, pool, 1000);
        // 1%の手数料なので1000を送ったのに990しか届かない。帳簿に1000と書くと10が足りなくなる
        assertEq(fee.balanceOf(pool), 990);
        assertEq(fee.balanceOf(from), 0);
    }
}
