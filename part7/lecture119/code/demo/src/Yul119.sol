// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第119講のデモ: Yulブロックの中の値と文法
contract Yul119 {
    // リテラル三つ: 16進数、文字列、true
    function literals() public pure returns (uint256 h, bytes32 s, uint256 t) {
        assembly {
            h := 0xff
            s := "abc"
            t := true
        }
    }

    // 文字列リテラルをuint256の欄に入れてもビルドできる
    function stringAsNumber() public pure returns (uint256 r) {
        assembly {
            r := "abc"
        }
    }

    // オーバーフローチェックなし
    function wrapAdd() public pure returns (uint256 r) {
        assembly {
            r := add(not(0), 1)
        }
    }

    function wrapSub() public pure returns (uint256 r) {
        assembly {
            r := sub(0, 1)
        }
    }

    // 0で割ると0
    function divZero(uint256 a, uint256 b) public pure returns (uint256 r) {
        assembly {
            r := div(a, b)
        }
    }

    function divZeroSol(uint256 a, uint256 b) public pure returns (uint256) {
        return a / b;
    }

    function divZeroUnchecked(uint256 a, uint256 b) public pure returns (uint256) {
        unchecked { return a / b; }
    }

    // 同じビットを符号なしの数と見るか符号ありの数と見るかは命令が決める
    function compare() public pure returns (uint256 u, uint256 s) {
        assembly {
            let m := not(0)
            u := lt(m, 1)
            s := slt(m, 1)
        }
    }

    // let, :=, switch, for, break, continue, function, leave
    function all() public pure returns (uint256 r) {
        assembly {
            let x := 10
            switch x
            case 0 { r := 1 }
            case 10 { r := 2 }
            default { r := 3 }
            for { let i := 0 } lt(i, 5) { i := add(i, 1) } {
                if eq(i, 1) { continue }
                if eq(i, 4) { break }
                r := add(r, i)
            }
            function twice(a) -> b {
                if iszero(a) { leave }
                b := mul(a, 2)
            }
            r := add(r, twice(x))
        }
    }

    // 同じ足し算三つ
    function addSol(uint256 a, uint256 b) public pure returns (uint256) {
        return a + b;
    }

    function addUnchecked(uint256 a, uint256 b) public pure returns (uint256) {
        unchecked { return a + b; }
    }

    function addAsm(uint256 a, uint256 b) public pure returns (uint256 r) {
        assembly { r := add(a, b) }
    }
}
