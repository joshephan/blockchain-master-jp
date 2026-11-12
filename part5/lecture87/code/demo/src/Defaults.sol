// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Defaults {
    function show() external pure returns (uint256, bool, address, uint256) {
        uint256 n;
        bool ok;
        address who;
        uint256[] memory list;
        return (n, ok, who, list.length);
    }
}
