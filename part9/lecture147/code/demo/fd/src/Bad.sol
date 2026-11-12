// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Bad {
    /// @notice 預け入れ
    /// @param amout 預ける量
    /// @foo 存在しないタグ
    function deposit(uint256 amount) external {}
}
