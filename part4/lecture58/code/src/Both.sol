// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

contract Both {
    function literalsOnly() external pure returns (uint256) {
        uint256 b = 200 + 100;
        return b;
    }
}
