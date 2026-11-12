// SPDX-License-Identifier: GPL-3.0

contract Late {
    function f() external pure returns (uint) {
        return 1;
    }
}

pragma solidity 0.8.30;
import {IToken} from "../src/IToken.sol";
