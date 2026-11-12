// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Market} from "./Market.sol";

contract Getter2 {
    function depositedOf(Market m, address asset, address user) external view returns (uint256 d) {
        (d, , , ) = m.positions(asset, user);
    }
}
