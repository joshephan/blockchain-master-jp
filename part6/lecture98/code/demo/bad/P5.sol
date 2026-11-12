// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract P5 {
    function f() external pure returns (address) { return msg.sender; }
}
