// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Nat {
    /// @param x 受け取る値
    function _f(uint256 x) internal pure returns (uint256) {
        return x;
    }

    /// @notice 預け入れ
    /// @return 存在しない戻り値
    event Deposited(uint256 amount);
}
