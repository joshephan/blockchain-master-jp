// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 残高の帳簿なしでTransferイベントだけを出すコントラクト(デモ用)
contract FakeEmitter {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function fire(address from, address to, uint256 value) external {
        emit Transfer(from, to, value);
    }
}
