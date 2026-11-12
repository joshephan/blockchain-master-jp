// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

// 実装の最初の版。値一つと減らす処理
contract Box {
    uint256 public value;

    event Burned(uint256 amount);

    function set(uint256 v) external {
        value = v;
    }

    function burn(uint256 amount) external {
        value -= amount;
        emit Burned(amount);
    }

    function version() external pure returns (uint256) {
        return 1;
    }
}

// 実装の二つ目の版。配置は同じ、関数を一つ追加
contract BoxV2 {
    uint256 public value;

    event Burned(uint256 amount);

    function set(uint256 v) external {
        value = v;
    }

    function burn(uint256 amount) external {
        value -= amount;
        emit Burned(amount);
    }

    function double() external {
        value *= 2;
    }

    function version() external pure returns (uint256) {
        return 2;
    }
}
