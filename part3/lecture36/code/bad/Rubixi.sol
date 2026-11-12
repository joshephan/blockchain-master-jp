// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Rubixi {
    address private owner;

    function Rubixi() public {
        owner = msg.sender;
    }
}
