// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 初期化関数の引数名が状態変数と同じ版
contract ShadowInit {
    address public owner;
    bool public done;

    function initialize(address owner) external {
        require(!done, "done");
        done = true;
        owner = owner;
    }
}
