// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract T1 {
    address public owner;

    function pay() external {
        owner.transfer(1 ether);
    }
}
