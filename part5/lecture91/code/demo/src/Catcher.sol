// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Target} from "./Target.sol";

contract Catcher {
    Target public t;
    uint256 public tries;

    event Caught(string reason);
    event GasLeft(uint256 gas);

    constructor(Target t_) {
        t = t_;
    }

    function tryRequire() external {
        tries += 1;
        try t.failRequire() {
        } catch Error(string memory reason) {
            emit Caught(reason);
        }
    }

    function tryBurn() external {
        try t.burn() {
        } catch {
            emit GasLeft(gasleft());
        }
    }

    function tryLowGas() external {
        try t.ok{gas: 5000}() returns (bool) {
        } catch {
            emit GasLeft(gasleft());
        }
    }
}
