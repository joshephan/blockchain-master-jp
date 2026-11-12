// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// ドキュメント(The Optimizer、Opcode-Based Optimizer Module)の例を関数一つで包む
contract DocOpt139 {
    mapping(uint256 => uint256) data;

    function f() external returns (uint256) {
        uint x = 7;
        data[7] = 9;
        if (data[x] != x + 2) // this condition is never true
          return 2;
        else
          return 1;
    }
}
