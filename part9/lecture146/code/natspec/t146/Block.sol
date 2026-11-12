// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Block {
    /**
     * @notice アスタリスク形式のnotice
     * @dev 二行で
     *      続けて書く
     */
    function f() external {}

    /// タグのない一行目
    /// タグのない二行目
    function g() external {}

    /// @notice 最初のnotice
    /// @notice 二つ目のnotice
    function h() external {}
}
