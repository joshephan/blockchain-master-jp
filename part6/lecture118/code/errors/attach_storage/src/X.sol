// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
struct Box { uint256 amount; }
library BoxLib { function put(Box storage b, uint256 x) internal { b.amount += x; } }
contract C { using BoxLib for Box; Box box; function f(uint256 x) external { box.put(x); } function g(uint256 x) external view { Box memory m = box; m.put(x); } }
