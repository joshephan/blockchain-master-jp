// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {M} from "@m/M.sol";

contract A {
    function v() external pure returns (uint256) {
        return M.v();
    }
}
