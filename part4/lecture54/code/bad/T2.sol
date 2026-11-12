// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract T2 {
    address payable public feeTo;

    function set() external {
        feeTo = msg.sender;
    }
}
