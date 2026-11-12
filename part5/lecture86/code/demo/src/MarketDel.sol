// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Market, IERC20, Amount} from "./Market.sol";

// デモ用: 全部引き出すとPositionをdeleteする版 (プロジェクトのコードには入れない)
contract MarketDel is Market {
    function withdrawAndClear(address asset, uint256 amount) external {
        _debit({asset: asset, user: msg.sender, amount: amount});
        if (Amount.unwrap(positions[asset][msg.sender].deposited) == 0) {
            delete positions[asset][msg.sender];
        }
        bool ok = IERC20(asset).transfer(msg.sender, amount);
        require(ok, "transfer failed");
    }
}
