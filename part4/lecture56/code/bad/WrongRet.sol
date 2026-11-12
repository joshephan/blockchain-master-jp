// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from "../src/Types.sol";

contract WrongRet {
    function pay(IERC20 t, address to) external returns (uint256) {
        uint256 r = t.transfer(to, 100);
        return r;
    }
}
