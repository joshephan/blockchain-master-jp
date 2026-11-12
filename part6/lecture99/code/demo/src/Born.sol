// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第92講: 生成時に載せて送ったイーサ、そのときのコード長
contract Born {
    uint256 public balanceAtStart;
    uint256 public codeLenAtStart;
    constructor() payable {
        balanceAtStart = address(this).balance;
        codeLenAtStart = address(this).code.length;
    }
}
