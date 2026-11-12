// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第116講のデモ: ライブラリ関数にstorage引数で欄を渡す
struct Box {
    uint256 amount;
    uint64 updated;
}

library BoxLib {
    function put(Box storage b, uint256 amount) internal {
        b.amount += amount;
        b.updated = uint64(block.timestamp);
    }

    // memoryで受け取るとコピーを直す
    function putCopy(Box memory b, uint256 amount) internal view {
        b.amount += amount;
        b.updated = uint64(block.timestamp);
    }
}

contract Shelf {
    mapping(address => Box) public boxes;

    function put(uint256 amount) external {
        BoxLib.put(boxes[msg.sender], amount);
    }

    function putCopy(uint256 amount) external view {
        BoxLib.putCopy(boxes[msg.sender], amount);
    }
}
