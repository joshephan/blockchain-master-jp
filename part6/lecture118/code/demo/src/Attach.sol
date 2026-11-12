// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Percent} from "./Percent.sol";
import {Box, BoxLib} from "./Shelf.sol";

// 第118講のデモ: ライブラリ名を書いて呼ぶ版とusing forで付けて呼ぶ版
contract FeeDirect {
    function fee(uint256 amount) external pure returns (uint256) {
        return Percent.part(amount, 3);
    }
}

contract FeeAttach {
    using Percent for uint256;

    function fee(uint256 amount) external pure returns (uint256) {
        return amount.part(3);
    }
}

// storage引数を受け取る関数も同じ形
contract ShelfAttach {
    using BoxLib for Box;
    mapping(address => Box) public boxes;

    function put(uint256 amount) external {
        boxes[msg.sender].put(amount);
    }

    function putCopy(uint256 amount) external view {
        BoxLib.putCopy(boxes[msg.sender], amount);
    }
}
