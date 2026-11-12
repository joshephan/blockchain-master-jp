// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract E {
    function base() external pure returns (uint256 x) {
        x = erc7201("example.main");
    }
}
