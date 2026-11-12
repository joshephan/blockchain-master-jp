// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {GateErr} from "./GateErr.sol";

contract Caller {
    uint256 public reached;

    function callNormal(GateErr gate) external {
        gate.open();
        reached += 1;
    }

    function callLow(address gate) external {
        gate.call(abi.encodeWithSignature("open()"));
        reached += 1;
    }
}
