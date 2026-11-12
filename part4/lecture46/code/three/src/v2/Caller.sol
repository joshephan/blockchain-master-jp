// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Caller {
    function ping() external pure returns (uint) {
        return 2;
    }
}
