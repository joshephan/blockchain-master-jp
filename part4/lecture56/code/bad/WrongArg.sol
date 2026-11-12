// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from "../src/Types.sol";

contract WrongArg {
    function pay(IERC20 t, address to) external {
        t.transfer(to, true);
    }
}
