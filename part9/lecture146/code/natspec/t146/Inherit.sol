// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

interface IBox {
    /// @notice 値を入れる
    /// @dev インターフェースのdev
    /// @param v 入れる値
    function put(uint256 v) external;

    /// @notice 入れた値
    /// @return 今の値
    function value() external view returns (uint256);
}

/// ドキュメントなしの実装
contract A is IBox {
    uint256 public value;
    function put(uint256 v) external { value = v; }
}

/// devを一行だけ書いた実装
contract B is IBox {
    uint256 public value;
    /// @dev Bのdev
    function put(uint256 v) external { value = v; }
}

/// パラメーター名を変えた実装
contract C is IBox {
    uint256 public value;
    function put(uint256 x) external { value = x; }
}

/// inheritdocとdev
contract D is IBox {
    /// @inheritdoc IBox
    uint256 public value;
    /// @inheritdoc IBox
    /// @dev Dのdev
    function put(uint256 v) external { value = v; }
}
