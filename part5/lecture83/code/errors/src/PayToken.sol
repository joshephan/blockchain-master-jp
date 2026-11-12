// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {IERC20} from "./Market.sol";

contract PayToken {
    function pull(IERC20 token, uint256 amount) external {
        token.transferFrom{value: 1}(msg.sender, address(this), amount);
    }
}
