// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第116講のデモ: ライブラリ関数の中から見たmsg.senderとaddress(this)
library WhoLib {
    event Seen(address sender, address self);

    function see() internal {
        emit Seen(msg.sender, address(this));
    }
}

contract Who {
    function hello() external {
        WhoLib.see();
    }
}
