// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Esc {
    function f() external pure returns (bytes memory, bytes memory, uint256) {
        bytes memory a = "line1\nline2\t\x41\"q\"";
        bytes memory b = "\uC548";
        return (a, b, b.length);
    }
}
