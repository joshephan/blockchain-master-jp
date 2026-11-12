// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Addr {
    address public owner;
    address payable public feeTo;
    bool public paused;
    address public guardian;

    constructor() {
        owner = msg.sender;
        feeTo = payable(msg.sender);
    }

    function toUint(address a) external pure returns (uint160) {
        return uint160(a);
    }

    function toBytes(address a) external pure returns (bytes20) {
        return bytes20(a);
    }

    function fromUint(uint160 n) external pure returns (address) {
        return address(n);
    }

    function widen(address payable p) external pure returns (address) {
        address a = p;
        return a;
    }
}
