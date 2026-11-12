// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Test, Vm} from "forge-std/Test.sol";
import {Message, Msg} from "../src/Msg57.sol";
import {ToyOutbox} from "../src/Outbox57.sol";

// テスト共通: チェーン番号三つと、outboxのログからメッセージを取り出す関数
abstract contract Base57 is Test {
    uint256 constant A = 57001;
    uint256 constant B = 57002;
    uint256 constant C = 57003;

    // 今残ったMessageSentログからメッセージを取り出す(中継する側がする仕事)
    function _lastMessage() internal view returns (bytes32 id, Message memory m) {
        Vm.Log[] memory logs = vm.getRecordedLogs();
        bytes32 topic = ToyOutbox.MessageSent.selector;
        for (uint256 i = logs.length; i > 0; i--) {
            if (logs[i - 1].topics[0] == topic) {
                id = logs[i - 1].topics[1];
                m = abi.decode(logs[i - 1].data, (Message));
                assertEq(Msg.idOf(m), id);
                return (id, m);
            }
        }
        revert("no MessageSent");
    }

    function _one(uint256 x) internal pure returns (uint256[] memory a) {
        a = new uint256[](1);
        a[0] = x;
    }

    function _oneAddr(address x) internal pure returns (address[] memory a) {
        a = new address[](1);
        a[0] = x;
    }
}
