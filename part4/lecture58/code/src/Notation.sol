// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract Notation {
    uint256 public oneEther = 1e18;
    uint256 public twentyFive = 2.5e1;
    uint256 public million = 1_000_000;
    int256 public minusOne = -1;
    uint256 public top = 1 << 255;
    uint256 public ff = 0xff;
    uint256 public ff2 = 0x00ff;
    bytes2 public pair = 0x1234;
    uint256 public fee = 0.003e18;
}
