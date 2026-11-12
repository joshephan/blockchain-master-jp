// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Switch {
    function pick(uint256 x) external pure returns (uint256) {
        switch (x) {
            case 1: return 10;
            default: return 0;
        }
    }
}
