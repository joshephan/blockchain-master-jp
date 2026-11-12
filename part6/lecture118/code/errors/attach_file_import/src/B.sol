// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
import "./A.sol";
contract C { function fee(uint256 a) external pure returns (uint256) { return a.part(3); } }
