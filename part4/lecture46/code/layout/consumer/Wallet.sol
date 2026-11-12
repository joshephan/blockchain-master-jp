// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IToken} from "../src/interfaces/IToken.sol";

contract Wallet {
    function balance(IToken token) external view returns (uint) {
        return token.balanceOf(address(this));
    }
}
