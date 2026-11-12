// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Now {
    function time() external view returns (uint256) {
        return now;
    }
}
