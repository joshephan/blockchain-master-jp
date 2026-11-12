// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract R { function a() external view returns (uint) { return block.prevrandao; } function b() external view returns (uint) { return block.difficulty; } }
