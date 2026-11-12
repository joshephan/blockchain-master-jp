// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

type Amount is uint256;

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
}

struct Position {
    Amount deposited;
    Amount borrowed;
    uint64 lastUpdate;
    bool useAsCollateral;
}

struct Account {
    Amount limit;                         // 値型
    IERC20[] used;                        // 配列
    Position pos;                         // 別の構造体
    mapping(IERC20 => Amount) perAsset;   // マッピング
}
