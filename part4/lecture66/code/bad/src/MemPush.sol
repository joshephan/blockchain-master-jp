// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract MemPush {
    function make() external pure returns (uint256[] memory r) {
        r = new uint256[](2);
        r.push(1);
    }
}
