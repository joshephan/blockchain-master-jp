// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Ast {
    // 普通のコメント
    /// @notice 預け入れ
    /// @param amount 預ける量
    function deposit(uint256 amount) external {}

    /// @notice 状態
    enum Mode { On, Off }

    /// @notice 内側
    function _f() internal {}
}
