// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract Y { function f(uint x) external pure returns (uint r) { assembly { r := clz(x) } } }
