// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract LocalBytes {
    function f() external pure returns (uint256) {
        bytes32 fixedOne = "abc";
        bytes dynamicOne = "abc";
        return fixedOne.length + dynamicOne.length;
    }
}
