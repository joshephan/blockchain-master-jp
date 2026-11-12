// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
event Noted(address who, uint256 n);
contract X {
    function note(uint256 n) external { emit Noted(msg.sender, n); }
}
