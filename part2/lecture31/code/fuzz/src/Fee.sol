// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Fee {
    // 手数料0.3%
    function fee(uint256 amount) public pure returns (uint256) {
        return amount * 3 / 1000;
    }
}
