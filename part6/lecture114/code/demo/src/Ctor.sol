// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第114講のデモ: コンストラクタの引数と実行の順番
contract Trace {
    event Step(string what, uint256 value);

    function mark(string memory what, uint256 value) internal returns (uint256) {
        emit Step(what, value);
        return value;
    }
}

contract Base is Trace {
    uint256 public b = mark("Base var", 1);
    address public immutable owner;

    constructor(address o) {
        owner = o;
        emit Step("Base ctor", hook());
    }

    // 子が書き換える関数
    function hook() internal virtual returns (uint256) {
        return 100;
    }
}

abstract contract Left is Base {
    uint256 public l = mark("Left var", 2);

    constructor() {
        emit Step("Left ctor", uint256(uint160(owner)));
    }
}

abstract contract Right is Base {
    uint256 public r;

    constructor(uint256 r_) {
        r = r_;
        emit Step("Right ctor", r_);
    }
}

contract Top is Left, Right {
    uint256 public t = mark("Top var", 4);

    // 書いた順番はRight、Base。実行の順番はBase、Left、Right、Top
    constructor(address o, uint256 r_) Right(r_) Base(o) {
        emit Step("Top ctor", t);
    }

    // Baseのコンストラクタが呼ぶとき、rはRightのコンストラクタがまだ実行されていないので0
    function hook() internal view override returns (uint256) {
        return r * 1000 + t;
    }
}

// 継承の行に引数を書く形
contract Fixed is Base(address(0xA11CE)) {}
