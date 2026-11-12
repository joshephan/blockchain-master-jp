// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
// 第80講: 受け取る関数を通さずにイーサを押し込む
contract Push { constructor(address payable to) payable { selfdestruct(to); } }
