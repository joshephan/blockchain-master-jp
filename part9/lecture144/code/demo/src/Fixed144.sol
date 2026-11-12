// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 第144講: 値を一つストレージから読んで返す箱
contract Box144 {
    uint256 public v = 7;
}

// 第144講: 渡すガスを2000と決めておいて箱を読む呼び出し。足りなければ失敗を返す
contract Fixed144 {
    function peek(Box144 box) external view returns (bool ok, uint256 v) {
        try box.v{gas: 2000}() returns (uint256 x) {
            return (true, x);
        } catch {
            return (false, 0);
        }
    }
}
