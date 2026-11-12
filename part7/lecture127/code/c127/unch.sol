// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0;
contract U {
    function dec(uint256 x) external pure returns (uint256) { unchecked { return x - 1; } }
}
