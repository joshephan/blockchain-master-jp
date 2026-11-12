// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.30;

contract Wallet {
    address public owner;

    function Wallet() public {
        owner = msg.sender;
    }
}
