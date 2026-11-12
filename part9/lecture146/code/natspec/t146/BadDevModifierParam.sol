// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract X {
    /// @param z 名前が違う
    modifier only(uint256 a) { _; }
}
