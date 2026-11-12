// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;
pragma abicoder v1;

contract Small_v1 {
    function echo(uint8 x) external pure returns (uint256) {
        return x;
    }
}
