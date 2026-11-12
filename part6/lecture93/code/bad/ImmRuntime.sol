// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Imm} from "../src/Imm.sol";

contract ImmRuntime {
    function len() external pure returns (uint256) {
        return type(Imm).runtimeCode.length;
    }
}
