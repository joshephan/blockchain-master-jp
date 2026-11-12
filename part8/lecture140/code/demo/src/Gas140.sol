// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// することが同じ計算
contract Worker {
    function work(uint256 n) external pure returns (uint256 acc) {
        for (uint256 i = 0; i < n; i++) {
            acc = acc * 31 + i;
        }
    }
}

// 決めておいたガスだけを渡して呼ぶ
contract Caller {
    function tryWork(Worker w, uint256 n, uint256 g) external pure returns (bool ok, uint256 r) {
        try w.work{gas: g}(n) returns (uint256 v) {
            return (true, v);
        } catch {
            return (false, 0);
        }
    }
}
