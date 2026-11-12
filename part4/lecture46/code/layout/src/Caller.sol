// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {IToken} from "./interfaces/IToken.sol";

contract Caller {
    function send(IToken token, address to, uint amount) external returns (bool) {
        return token.transfer(to, amount);
    }
}
