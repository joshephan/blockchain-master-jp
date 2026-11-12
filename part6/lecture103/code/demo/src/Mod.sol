// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第103講: 複数のmodifierの順番と引数の計算タイミング
contract Order {
    event Step(string where, uint256 value);
    uint256 public n;

    function mark(string memory w) internal returns (uint256) {
        n += 1;
        emit Step(w, n);
        return n;
    }

    modifier a(uint256 x) {
        emit Step("a before", x);
        _;
        emit Step("a after", x);
    }

    modifier b(uint256 x) {
        emit Step("b before", x);
        _;
        emit Step("b after", x);
    }

    function run() external a(mark("arg of a")) b(mark("arg of b")) {
        emit Step("body", n);
    }

    function runSwapped() external b(mark("arg of b")) a(mark("arg of a")) {
        emit Step("body", n);
    }
}

// 第103講: _;が実行される回数
contract Count {
    uint256 public count;

    modifier twice() { _; _; }
    modifier thrice() { for (uint256 i = 0; i < 3; i++) { _; } }
    modifier onlyIf(bool c) { if (c) { _; } }

    function two() external twice { count += 1; }
    function three() external thrice { count += 1; }
    function maybe(bool c) external onlyIf(c) returns (uint256) {
        count += 1;
        return 7;
    }
}

// 第103講: 本文でreturnしても_;の後ろは実行される
contract After {
    uint256 public post;
    uint256 public calls;

    modifier tail() {
        _;
        post += 1;
    }

    function early(bool stop) external tail returns (uint256) {
        if (stop) {
            return 5;
        }
        calls += 1;
        return 9;
    }

    function fail() external tail {
        calls += 1;
        revert("body failed");
    }
}

// 第103講: 内部呼び出しでもmodifierが動く、関数の引数をmodifierに渡す
contract Inner {
    uint256 public checks;

    modifier counted() {
        checks += 1;
        _;
    }

    modifier positive(uint256 v) {
        require(v > 0, "zero value");
        _;
    }

    function inner(uint256 v) public counted positive(v) returns (uint256) {
        return v * 2;
    }

    function outer(uint256 v) external counted returns (uint256) {
        return inner(v);
    }
}
