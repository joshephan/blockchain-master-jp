// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

/// @title タグが付く場所の一覧
/// @author 講義の例
/// @notice コントラクトの上のnotice
/// @dev コントラクトの上のdev
/// @custom:security-contact 例なのでアドレスなし
contract Kinds {
    /// @notice 状態の上のnotice
    /// @dev 状態の上のdev
    enum Mode {
        /// @notice 値の上のnotice
        On,
        Off
    }

    /// @notice 構造体の上のnotice
    struct P { uint256 a; }

    /// @notice 預けた量
    /// @dev ユーザーのアドレスをキーにする
    /// @return 預けた量そのまま
    mapping(address => uint256) public balanceOf;

    /// @dev 内部でだけ使う合計
    uint256 internal total;

    /// @notice 預け入れを知らせるログ
    /// @param user 預けたアカウント
    /// @param amount 預けた量
    event Deposited(address indexed user, uint256 amount);

    /// @notice 預けた量より多く引き出すとき
    /// @param have 預けた量
    /// @param want 引き出そうとする量
    error Insufficient(uint256 have, uint256 want);

    /// @notice コンストラクタのnotice
    /// @param start 最初の合計
    constructor(uint256 start) { total = start; }

    /// @notice 引き出し
    /// @dev 足りなければInsufficient
    /// @param amount 引き出す量
    /// @return left 残った量
    function withdraw(uint256 amount) external returns (uint256 left) {
        uint256 have = balanceOf[msg.sender];
        if (have < amount) revert Insufficient(have, amount);
        left = _sub(have, amount);
        balanceOf[msg.sender] = left;
    }

    /// @notice 内側の引き算
    /// @param a 前の値
    /// @param b 後ろの値
    function _sub(uint256 a, uint256 b) internal pure returns (uint256) { return a - b; }

    /// @notice 受け取る関数
    receive() external payable { emit Deposited(msg.sender, msg.value); }
}
