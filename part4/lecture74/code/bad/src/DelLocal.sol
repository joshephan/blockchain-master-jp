// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract DelLocal {
    uint256[] public data;

    function f() external {
        uint256[] storage y = data;
        delete y;
    }
}
