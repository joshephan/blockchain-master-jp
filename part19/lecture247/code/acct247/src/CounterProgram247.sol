// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {CounterData247} from "./CounterData247.sol";

// プログラムのまね: 状態変数なし、直すデータアカウントを引数で受け取る
contract CounterProgram247 {
    error WrongOwner(address account, address owner);

    function create() external returns (CounterData247) {
        return new CounterData247(address(this));
    }

    function increment(CounterData247 account) external {
        // 渡されたアカウントがこのプログラムのものか確認
        address o = account.owner();
        if (o != address(this)) revert WrongOwner(address(account), o);
        account.write(account.count() + 1);
    }
}
