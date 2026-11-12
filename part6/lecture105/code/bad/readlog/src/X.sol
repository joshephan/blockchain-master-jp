// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract X {
    event Noted(address who, uint256 n);
    function last() external view returns (uint256) { return Noted.n; }
}
