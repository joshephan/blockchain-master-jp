// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
import {Amount} from "./T.sol";
contract C { function f(Amount a) external pure returns (Amount) { return a.twice(); } }
