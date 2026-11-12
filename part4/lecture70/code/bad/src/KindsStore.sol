// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Account, Amount} from "./Kinds.sol";

contract KindsStore {
    Account acc;

    function limitOf() external view returns (uint256) {
        Account storage a = acc;
        return Amount.unwrap(a.limit);
    }
}
