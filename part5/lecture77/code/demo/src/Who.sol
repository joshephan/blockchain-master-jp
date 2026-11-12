// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Who {
    event Seen(string where, address sender);

    modifier logSender() {
        emit Seen("modifier", msg.sender);
        _;
    }

    function outer() external logSender {
        emit Seen("outer", msg.sender);
        inner();
        this.viaThis();
        emit Seen("after", msg.sender);
    }

    function inner() internal {
        emit Seen("inner", msg.sender);
    }

    function viaThis() external {
        emit Seen("viaThis", msg.sender);
    }
}
