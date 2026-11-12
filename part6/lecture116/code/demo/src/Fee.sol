// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Percent, PercentMany} from "./Percent.sol";

// ライブラリ関数を呼ぶ版
contract FeeLib {
    function fee(uint256 amount) external pure returns (uint256) {
        return Percent.part(amount, 3);
    }
}

// 同じ計算をコントラクト内のinternal関数で書いた版
contract FeeInline {
    function fee(uint256 amount) external pure returns (uint256) {
        return _of(amount, 3);
    }

    function _of(uint256 amount, uint256 pct) internal pure returns (uint256) {
        return amount * pct / 100;
    }
}

// 呼ばない関数が19個多いライブラリを呼ぶ版
contract FeeMany {
    function fee(uint256 amount) external pure returns (uint256) {
        return PercentMany.part(amount, 3);
    }
}

// 同じ計算を親コントラクトに書いて継承した版
abstract contract PercentBase {
    function _of(uint256 amount, uint256 pct) internal pure returns (uint256) {
        return amount * pct / 100;
    }
}

contract FeeInherit is PercentBase {
    function fee(uint256 amount) external pure returns (uint256) {
        return _of(amount, 3);
    }
}
