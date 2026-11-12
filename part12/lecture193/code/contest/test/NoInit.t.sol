// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {Market, IERC20, Ratio, Rate} from "../src/Market.sol";
import {IMarket} from "../src/IMarket.sol";

// 第177講: 初期化関数がなく、管理者はコンストラクタが同じデプロイトランザクションで決める。ランタイムコードにDELEGATECALL・SELFDESTRUCT・ORIGINなし
contract NoInitTest is Test {
    Market market;
    address bob = address(0xB0B);

    function setUp() public {
        market = new Market(address(this), Rate.wrap(5e16), Ratio.wrap(80));
    }

    function test_adminSetAtDeploy() public view {
        assertEq(market.admin(), address(this));
    }

    function test_noInitializer() public {
        vm.prank(bob);
        (bool ok,) = address(market).call(abi.encodeWithSignature("initialize(address)", bob));
        assertFalse(ok);
        assertEq(market.admin(), address(this));
    }

    function test_zeroAdminRejected() public {
        vm.expectRevert(IMarket.ZeroAdmin.selector);
        new Market(address(0), Rate.wrap(5e16), Ratio.wrap(80));
    }

    // 命令のバイトだけを読む(PUSHの後ろのデータと末尾のメタデータは飛ばす)
    function test_opcodeCounts() public view {
        bytes memory code = address(market).code;
        uint256 n = code.length;
        uint256 end = n - 2 - (uint256(uint8(code[n - 2])) << 8 | uint256(uint8(code[n - 1])));
        uint256 delegatecalls;
        uint256 selfdestructs;
        uint256 origins;
        for (uint256 i = 0; i < end; i++) {
            uint8 op = uint8(code[i]);
            if (op == 0xf4) delegatecalls++;
            if (op == 0x32) origins++;
            if (op == 0xff) selfdestructs++;
            if (op >= 0x60 && op <= 0x7f) i += op - 0x5f;
        }
        assertEq(delegatecalls, 0);
        assertEq(origins, 0);
        assertEq(selfdestructs, 0);
    }
}
