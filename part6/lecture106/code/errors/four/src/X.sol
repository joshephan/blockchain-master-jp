// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract X {
    event Four(uint256 indexed a, uint256 indexed b, uint256 indexed c, uint256 indexed d);

    function f() external {
        emit Four(1, 2, 3, 4);
    }
}
