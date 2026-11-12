// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "../src/Market.sol";

// 受け取ったcalldataをそのまま記録しておくテスト用トークン
contract RecordToken {
    bytes public last;

    function transferFrom(address, address, uint256) external returns (bool) {
        last = msg.data;
        return true;
    }
}

contract PullBytesTest is Test {
    function test_sameBytes() public {
        RecordToken t = new RecordToken();
        address alice = address(0xA11CE);
        IERC20(address(t)).transferFrom(alice, address(this), 500);
        bytes memory built = abi.encodeCall(IERC20.transferFrom, (alice, address(this), 500));
        assertEq(t.last(), built);
        assertEq(t.last().length, 100);
    }
}
