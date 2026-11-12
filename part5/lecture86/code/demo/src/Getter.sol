// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Market, Amount} from "./Market.sol";

// positionsゲッターから預けた量だけを受け取る
contract Getter {
    function depositedOf(Market m, address asset, address user) external view returns (uint256) {
        (Amount d, , , ) = m.positions(asset, user);
        return Amount.unwrap(d);
    }
}
