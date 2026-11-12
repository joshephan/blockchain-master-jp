// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Box} from "./Shelf.sol";

// 第117講のデモ: public関数があるライブラリ。別にデプロイしてアドレスをリンクする
library BoxExt {
    event Put(address sender, address self, uint256 amount);

    function put(Box storage b, uint256 amount) public {
        b.amount += amount;
        b.updated = uint64(block.timestamp);
        emit Put(msg.sender, address(this), amount);
    }

    function peek(Box storage b) public view returns (uint256) {
        return b.amount;
    }

    function part(uint256 amount, uint256 pct) public pure returns (uint256) {
        return amount * pct / 100;
    }
}

contract ShelfExt {
    address public admin;
    mapping(address => Box) public boxes;

    constructor() {
        admin = msg.sender;
    }

    function put(uint256 amount) external {
        BoxExt.put(boxes[msg.sender], amount);
    }

    function peek() external view returns (uint256) {
        return BoxExt.peek(boxes[msg.sender]);
    }

    function fee(uint256 amount) external pure returns (uint256) {
        return BoxExt.part(amount, 3);
    }
}

// 同じ本体をinternalにした版 (ガス比較用)
library BoxIn {
    event Put(address sender, address self, uint256 amount);

    function put(Box storage b, uint256 amount) internal {
        b.amount += amount;
        b.updated = uint64(block.timestamp);
        emit Put(msg.sender, address(this), amount);
    }
}

contract ShelfIn {
    address public admin;
    mapping(address => Box) public boxes;

    constructor() {
        admin = msg.sender;
    }

    function put(uint256 amount) external {
        BoxIn.put(boxes[msg.sender], amount);
    }
}

// リンク先に入れてみる別のコントラクト。ライブラリではない
contract NotBoxExt {
    address admin;

    fallback() external {
        admin = msg.sender;
    }
}
