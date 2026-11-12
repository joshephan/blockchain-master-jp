// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract AddrFromU256 {
    function f(uint256 x) external pure returns (address) {
        return address(x);
    }
}
