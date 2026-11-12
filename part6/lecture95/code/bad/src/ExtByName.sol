// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract ExtByName {
    function ext() external pure returns (uint256) { return 1; }

    function f() external pure returns (uint256) {
        return ext();
    }
}
