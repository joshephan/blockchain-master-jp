// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

type Amount is uint256;

// ファイルレベルの宣言
struct Position {
    Amount deposited;
    Amount borrowed;
    uint64 lastUpdate;
    bool useAsCollateral;
}

// インターフェース内の宣言
interface IMarket {
    struct Quote {
        address asset;
        uint256 amount;
    }
    function quote(address asset) external view returns (Quote memory);
}

// ライブラリ内の宣言
library PosLib {
    struct Snapshot {
        uint256 deposited;
        uint256 borrowed;
    }
}
