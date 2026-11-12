// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Amount, Position} from "./Types.sol";

contract Market {
    Position[] public positions;

    event Updated(uint256 i);

    // 順番どおりに渡す: 預けた量と借りた量を取り違えて書く
    function openSwapped(uint256 d, uint256 b) external {
        positions.push(Position(Amount.wrap(b), Amount.wrap(d), uint64(block.timestamp), true));
    }

    // 名前を付けて渡す
    function openNamed(uint256 d, uint256 b) external {
        positions.push(Position({
            deposited: Amount.wrap(d),
            borrowed: Amount.wrap(b),
            lastUpdate: uint64(block.timestamp),
            useAsCollateral: true
        }));
    }

    // storageの別名で三つのフィールドを直す
    function updateStorage(uint256 i, uint256 d, uint256 b) external {
        Position storage p = positions[i];
        p.deposited = Amount.wrap(d);
        p.borrowed = Amount.wrap(b);
        p.lastUpdate = uint64(block.timestamp);
        emit Updated(i);
    }

    // memoryのコピーで三つのフィールドを直し、書き戻しを忘れる
    function updateMemoryForgot(uint256 i, uint256 d, uint256 b) external {
        Position memory p = positions[i];
        p.deposited = Amount.wrap(d);
        p.borrowed = Amount.wrap(b);
        p.lastUpdate = uint64(block.timestamp);
        emit Updated(i);
    }

    // memoryのコピーで三つのフィールドを直し、一度に書き戻す
    function updateMemoryWriteBack(uint256 i, uint256 d, uint256 b) external {
        Position memory p = positions[i];
        p.deposited = Amount.wrap(d);
        p.borrowed = Amount.wrap(b);
        p.lastUpdate = uint64(block.timestamp);
        positions[i] = p;
        emit Updated(i);
    }

    function close(uint256 i) external {
        delete positions[i];
    }

    function count() external view returns (uint256) {
        return positions.length;
    }
}
