// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第118講のデモ: ユーザー定義値型に演算子を付ける
type Money is uint256;

// オーバーフローチェックがある足し算・引き算 (0.8のデフォルトの算術)
function add(Money a, Money b) pure returns (Money) {
    return Money.wrap(Money.unwrap(a) + Money.unwrap(b));
}

function sub(Money a, Money b) pure returns (Money) {
    return Money.wrap(Money.unwrap(a) - Money.unwrap(b));
}

function lt(Money a, Money b) pure returns (bool) {
    return Money.unwrap(a) < Money.unwrap(b);
}

using {add as +, sub as -, lt as <} for Money global;

// 同じ引き算をuncheckedで書いた型
type LooseMoney is uint256;

function looseSub(LooseMoney a, LooseMoney b) pure returns (LooseMoney) {
    unchecked {
        return LooseMoney.wrap(LooseMoney.unwrap(a) - LooseMoney.unwrap(b));
    }
}

using {looseSub as -} for LooseMoney global;

contract Till {
    function minus(Money a, Money b) external pure returns (Money) {
        return a - b;
    }

    function looseMinus(LooseMoney a, LooseMoney b) external pure returns (LooseMoney) {
        return a - b;
    }

    function less(Money a, Money b) external pure returns (bool) {
        return a < b;
    }

    // 演算子なしで同じ計算を書いた版
    function minusRaw(Money a, Money b) external pure returns (Money) {
        return Money.wrap(Money.unwrap(a) - Money.unwrap(b));
    }
}
