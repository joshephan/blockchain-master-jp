// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Narrow {
    function narrow(uint256 x) external pure returns (uint8) {
        return uint8(x);
    }
}
