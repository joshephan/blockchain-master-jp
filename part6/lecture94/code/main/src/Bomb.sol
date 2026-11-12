// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Bomb {
    uint256 public x = 42;

    function boom() external {
        selfdestruct(payable(msg.sender));
    }
}

contract BombFactory {
    function make(bytes32 salt) external returns (address) {
        return address(new Bomb{salt: salt}());
    }

    // 作ったトランザクションの中ですぐboom
    function makeAndBoom(bytes32 salt) external returns (address b) {
        b = address(new Bomb{salt: salt}());
        Bomb(b).boom();
    }
}
