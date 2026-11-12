// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
interface I2 {
    function balanceOf(address who) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
contract C { function id() external pure returns (bytes4) { return type(I2).interfaceId; } }
