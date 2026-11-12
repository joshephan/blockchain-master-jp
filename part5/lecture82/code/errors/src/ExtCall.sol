// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract ExtCall {
    function ping() external pure returns (uint256) {
        return 1;
    }

    function callPing() external pure returns (uint256) {
        return ping();
    }
}
