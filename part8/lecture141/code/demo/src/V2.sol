// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract V2 {
    enum Side { Buy, Sell }
    function take(uint8 x, bool b, address a, Side s) external pure returns (uint256, bool, address, uint8) { return (x, b, a, uint8(s)); }
    function name() external pure returns (string memory) { return "hi"; }
    function dirty() external pure returns (bytes memory) {
        uint8 x;
        assembly { x := 0x1ff }
        return abi.encode(x);
    }
}
