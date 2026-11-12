// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Oracle {
    function ok() external pure returns (bool) {
        return true;
    }
}

contract Guard {
    Oracle public oracle;

    constructor(Oracle o) {
        oracle = o;
    }

    function check(bool enabled) external view returns (bool) {
        if (enabled && oracle.ok()) {
            return true;
        }
        return false;
    }
}
