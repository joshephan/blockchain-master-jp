// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
pragma abicoder v1;

contract V1 {
    enum Side { Buy, Sell }
    function take(uint8 x, bool b, address a, Side s) external pure returns (uint256, bool, address, uint8) { return (x, b, a, uint8(s)); }
    function name() external pure returns (string memory) { return "hi"; }
}
