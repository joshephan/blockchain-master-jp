// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;
import {Test, console} from "forge-std/Test.sol";
import {I2} from "../src/I2.sol";
contract T is Test { function test_id() public pure { console.logBytes4(type(I2).interfaceId); } }
