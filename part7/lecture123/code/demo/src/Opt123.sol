// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第123講のデモ: 同じことを三通りで。コントラクトごとに関数一つなのでディスパッチャーの順番が混ざらない

// 1. calldata配列の合計
contract SumSol {
    function sum(uint256[] calldata xs) external pure returns (uint256 s) {
        for (uint256 i = 0; i < xs.length; i++) {
            s += xs[i];
        }
    }
}

contract SumUnchecked {
    function sum(uint256[] calldata xs) external pure returns (uint256 s) {
        uint256 n = xs.length;
        for (uint256 i = 0; i < n; ) {
            s += xs[i];
            unchecked { ++i; }
        }
    }
}

contract SumAsm {
    function sum(uint256[] calldata xs) external pure returns (uint256 s) {
        assembly {
            let p := xs.offset
            let end := add(p, mul(xs.length, 0x20))
            for { } lt(p, end) { p := add(p, 0x20) } {
                s := add(s, calldataload(p))
            }
        }
    }
}

// 2. カスタムエラーで巻き戻す
contract ErrSol {
    error ZeroAmount();
    function check(uint256 x) external pure returns (uint256) {
        if (x == 0) revert ZeroAmount();
        return x;
    }
}

contract ErrAsm {
    error ZeroAmount();
    function check(uint256 x) external pure returns (uint256) {
        assembly {
            if iszero(x) {
                mstore(0, shl(224, 0x1f2a2005)) // ZeroAmount()
                revert(0, 4)
            }
        }
        return x;
    }
}

// 3. 同じ状態変数を二回読む
contract ReadTwice {
    uint256 public v = 5;
    function f() external view returns (uint256) {
        return v * v + v;
    }
}

contract ReadCached {
    uint256 public v = 5;
    function f() external view returns (uint256) {
        uint256 x = v;
        return x * x + x;
    }
}

contract ReadUnchecked {
    uint256 public v = 5;
    function f() external view returns (uint256) {
        uint256 x = v;
        unchecked { return x * x + x; }
    }
}

contract ReadAsm {
    uint256 public v = 5;
    function f() external view returns (uint256 r) {
        assembly {
            let x := sload(v.slot)
            r := add(mul(x, x), x)
        }
    }
}
