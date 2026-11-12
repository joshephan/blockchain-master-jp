// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from "../src/Types.sol";

contract Implicit {
    function set(address a) external pure returns (IERC20) {
        IERC20 t = a;
        return t;
    }
}
