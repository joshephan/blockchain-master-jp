// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

import {Target} from "./Options.sol";

contract OldSyntax {
    function old(Target t) external {
        t.hit.value(7)(3);
    }
}
