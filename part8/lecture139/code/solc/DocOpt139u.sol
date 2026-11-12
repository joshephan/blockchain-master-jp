// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// DocOpt139でx + 2だけをuncheckedに変えた版
contract DocOpt139u {
    mapping(uint256 => uint256) data;

    function f() external returns (uint256) {
        uint x = 7;
        data[7] = 9;
        uint y;
        unchecked { y = x + 2; }
        if (data[x] != y) // this condition is never true
          return 2;
        else
          return 1;
    }
}
