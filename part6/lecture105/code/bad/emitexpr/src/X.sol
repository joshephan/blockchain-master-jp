// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract X {
    event Noted(address who, uint256 n);
    function note(uint256 n) external returns (bool) { bool ok = emit Noted(msg.sender, n); return ok; }
}
