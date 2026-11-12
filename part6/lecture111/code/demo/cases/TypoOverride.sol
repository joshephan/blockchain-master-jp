// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Counter} from "../src/Inh.sol";

contract ChildTypo is Counter {
    function stpe() public pure override returns (uint256) {
        return 10;
    }
}
