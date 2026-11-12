// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from "../src/Types.sol";

contract Typo {
    function pay(IERC20 t, address to) external {
        t.transfr(to, 100);
    }
}
