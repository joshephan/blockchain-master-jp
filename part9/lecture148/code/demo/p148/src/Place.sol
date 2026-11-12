// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Place {
    /// @notice Aのすぐ上
    function a() external {}

    /// @notice Bの上、間に普通のコメント
    // 普通のコメント一行
    function b() external {}

    // 普通のコメントを先に
    /// @notice Cのすぐ上、普通のコメントはその上
    function c() external {}

    /// @notice Dの上、間に空行

    function d() external {}

    /// @notice Eの一つ目のまとまり
    // 普通のコメント
    /// @notice Eの二つ目のまとまり
    function e() external {}
}
