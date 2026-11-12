// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract ExtCallThis {
    function ping() external pure returns (uint256) {
        return 1;
    }

    function callPing() external view returns (uint256) {
        return this.ping();
    }
}
