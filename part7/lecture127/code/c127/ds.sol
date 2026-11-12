// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
contract Y { function g() external pure returns (uint r) { assembly { r := datasize("Y") } } }
