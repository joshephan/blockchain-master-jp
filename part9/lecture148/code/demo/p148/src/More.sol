// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract A {
	uint256 x;
}


contract B {
    function f() public {}
}



import {A as A2} from "./Bad.sol";

interface IM {
    function divide(int256 n, int256 d) external returns (uint256);
    error DivideByZero();
}

contract C {
    function g(uint256 aaaaaaaaaaaaaaaaaaaaaa, uint256 bbbbbbbbbbbbbbbbbbbbbbbb, uint256 cccccccccccccccc) public pure returns (uint256) {
        return aaaaaaaaaaaaaaaaaaaaaa;
    }
    // かなの コメント 一行が 120 桁を 超えると どうなるか。 かな 一文字は 画面で 二桁, UTF-8 では 三バイト, 文字では 一文字 である 終わり
    string constant S = "かな 文字列 かな 文字列 かな 文字列 かな 文字列 かな 文字列 かな 文字列 かな 文字列 かな 文字列 かな 文字列";
    function h(uint256 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa, uint256 bbbbbbbbbbbbbbbbb) public pure returns (uint256 ccccc) {}
    function k(uint256 a) public pure returns (uint256) { return a; } // かな かな かな かな かな かな かな かな かな かな かな かな かな かな かな かな かな
}
