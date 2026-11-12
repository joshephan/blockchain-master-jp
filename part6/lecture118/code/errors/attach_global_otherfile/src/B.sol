// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
import {Amount} from "./T.sol";
library L { function twice(Amount a) internal pure returns (Amount) { return Amount.wrap(Amount.unwrap(a) * 2); } }
using L for Amount global;
