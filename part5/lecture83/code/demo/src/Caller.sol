// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {IERC20} from "./Market.sol";

// 同じtransferFromを二つの系統で呼ぶ
contract Caller {
    function typed(address token, address from, uint256 amount) external returns (bool) {
        return IERC20(token).transferFrom(from, address(this), amount);
    }

    function low(address token, address from, uint256 amount) external returns (bool ok, bytes memory ret) {
        (ok, ret) = token.call(abi.encodeCall(IERC20.transferFrom, (from, address(this), amount)));
    }
}

// 巻き戻すトークン
contract RevertToken {
    function transferFrom(address, address, uint256) external pure returns (bool) {
        revert("no allowance");
    }
}
