// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 最初の版: ownerはスロット0、totalはスロット1
contract LedgerV1 {
    address public owner;
    uint256 public total;

    function setup(address o, uint256 t) external {
        owner = o;
        total = t;
    }
}

// 真ん中にfeeを挟んだ版: feeはスロット1、totalはスロット2
contract LedgerV2Insert {
    address public owner;
    uint256 public fee;
    uint256 public total;
}

// 最後にfeeを付けた版: totalはスロット1のまま、feeはスロット2
contract LedgerV2Append {
    address public owner;
    uint256 public total;
    uint256 public fee;
}

// 親に変数が一つできた版: createdAtはスロット0、ownerは1、totalは2
contract Stamp {
    uint256 public createdAt;
}

contract LedgerV2Parent is Stamp {
    address public owner;
    uint256 public total;
}

// 開始スロットを動かした版(第135講のlayout at)。erc7201("course.ledger")の値
contract LedgerAt layout at 0x5faaca7103cb5180a377ac4272c65fac3890b581a0bebb7fd617513a33dc9f00 {
    address public owner;
    uint256 public total;

    function setup(address o, uint256 t) external {
        owner = o;
        total = t;
    }
}

// layout atの行を書き忘れた次の版
contract LedgerAtForgot {
    address public owner;
    uint256 public total;
}
